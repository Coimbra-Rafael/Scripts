-- Criação do banco de dados
-- CREATE DATABASE enterprise_resource_planning;
-- enterprise_resource_planning;

--------------------------------------------------
-- 0. Função para atualização do campo updated_at
--------------------------------------------------
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------
-- 1. Tabela de Planos
--------------------------------------------------
CREATE TABLE IF NOT EXISTS tb_plans (
    plan_id INT GENERATED BY DEFAULT AS IDENTITY NOT NULL PRIMARY KEY,
    plan_name VARCHAR(50) NOT NULL
);

--------------------------------------------------
-- 2. Tabela de Clientes
--------------------------------------------------
CREATE TABLE IF NOT EXISTS tb_customers (
    customer_id BIGINT GENERATED BY DEFAULT AS IDENTITY NOT NULL PRIMARY KEY,
    customer_name VARCHAR(200) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

--------------------------------------------------
-- 3. Configurações dos Clientes
--------------------------------------------------
CREATE TABLE IF NOT EXISTS tb_customers_config (
    customer_id BIGINT NOT NULL,
    customer_config_id INT GENERATED BY DEFAULT AS IDENTITY NOT NULL PRIMARY KEY,
    CONSTRAINT fk_tb_customers_config_customer
         FOREIGN KEY (customer_id)
             REFERENCES tb_customers(customer_id)
);

--------------------------------------------------
-- 4. Relacionamento entre Clientes e Planos (N:N)
--------------------------------------------------
CREATE TABLE IF NOT EXISTS tb_customers_plans (
    customer_id BIGINT NOT NULL,
    plan_id INT NOT NULL,
    PRIMARY KEY (customer_id, plan_id),
    CONSTRAINT fk_tb_customers_plans_customer
        FOREIGN KEY (customer_id)
            REFERENCES tb_customers(customer_id),
    CONSTRAINT fk_tb_customers_plans_plan
        FOREIGN KEY (plan_id)
            REFERENCES tb_plans(plan_id)
);

--------------------------------------------------
-- 5. Endereços dos Clientes (com melhorias)
--------------------------------------------------
CREATE TABLE IF NOT EXISTS tb_customers_address (
    customer_id BIGINT NOT NULL,
    address_id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    street_name VARCHAR(255) NOT NULL,
    street_number VARCHAR(20) NOT NULL,  -- Permite valores alfanuméricos (ex.: "S/N")
    city VARCHAR(255) NOT NULL,
    state VARCHAR(255) NOT NULL,
    country VARCHAR(255) NOT NULL,
    postal_code CHAR(9) NOT NULL,         -- Formato "12345-678"
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_tb_customers_address_customer
        FOREIGN KEY (customer_id)
            REFERENCES tb_customers(customer_id)
            ON DELETE CASCADE,
    CONSTRAINT chk_postal_code
        CHECK (postal_code ~ '^[0-9]{5}-[0-9]{3}$')
);

--------------------------------------------------
-- 6. Tabela de Empresas (com CPF/CNPJ validado)
--------------------------------------------------
CREATE TABLE IF NOT EXISTS tb_enterprise (
    customer_id BIGINT NOT NULL,
    enterprise_id INT GENERATED BY DEFAULT AS IDENTITY NOT NULL,
    company_name VARCHAR(255) NOT NULL,
    company_alias VARCHAR(255) NOT NULL,
    cpf_cnpj VARCHAR(14) NOT NULL,  -- Armazenar sem formatação (somente números)
    state_registration VARCHAR(9) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (customer_id, enterprise_id),
    CONSTRAINT fk_tb_enterprise_customer
        FOREIGN KEY (customer_id)
            REFERENCES tb_customers(customer_id),
    CONSTRAINT chk_cpf_cnpj
        CHECK (char_length(regexp_replace(cpf_cnpj, '[^0-9]', '', 'g')) IN (11, 14))
);

--------------------------------------------------
-- 7. Endereços das Empresas
--------------------------------------------------
CREATE TABLE IF NOT EXISTS tb_enterprise_address (
    customer_id BIGINT NOT NULL,
    enterprise_id INT NOT NULL,
    address_id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    street_name VARCHAR(255) NOT NULL,
    street_number VARCHAR(20) NOT NULL,
    city VARCHAR(255) NOT NULL,
    state VARCHAR(255) NOT NULL,
    country VARCHAR(255) NOT NULL,
    postal_code CHAR(9) NOT NULL,
    CONSTRAINT fk_tb_enterprise_address_enterprise
        FOREIGN KEY (customer_id, enterprise_id)
            REFERENCES tb_enterprise(customer_id, enterprise_id)
            ON DELETE CASCADE,
    CONSTRAINT chk_postal_code_ent
        CHECK (postal_code ~ '^[0-9]{5}-[0-9]{3}$')
);

--------------------------------------------------
-- 8. Configurações das Empresas
--------------------------------------------------
CREATE TABLE IF NOT EXISTS tb_enterprise_config (
    customer_id BIGINT NOT NULL,
    enterprise_id INT NOT NULL,
    enterprise_config_id INT GENERATED BY DEFAULT AS IDENTITY NOT NULL PRIMARY KEY,
    certificate_name VARCHAR(255) NULL,
    certificate_content TEXT NULL,
    expiration_date DATE NULL,
    CONSTRAINT fk_tb_enterprise_config_enterprise
         FOREIGN KEY (customer_id, enterprise_id)
            REFERENCES tb_enterprise(customer_id, enterprise_id)
);

--------------------------------------------------
-- 9. Usuários (Clientes)
--------------------------------------------------
CREATE TABLE IF NOT EXISTS tb_users (
    customer_id BIGINT NOT NULL,
    user_id INT GENERATED BY DEFAULT AS IDENTITY NOT NULL,
    username VARCHAR(150) UNIQUE NOT NULL,
    password VARCHAR(150) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (customer_id, user_id),
    CONSTRAINT fk_tb_users_customer
        FOREIGN KEY (customer_id)
            REFERENCES tb_customers(customer_id)
);

--------------------------------------------------
-- 10. Relacionamento entre Usuários e Empresas
--------------------------------------------------
CREATE TABLE IF NOT EXISTS tb_users_enterprise (
    customer_id BIGINT NOT NULL,
    user_id INT NOT NULL,
    enterprise_id INT NOT NULL,
    PRIMARY KEY (customer_id, user_id, enterprise_id),
    CONSTRAINT fk_tb_users_enterprise_user
        FOREIGN KEY (customer_id, user_id)
            REFERENCES tb_users(customer_id, user_id),
    CONSTRAINT fk_tb_users_enterprise_enterprise
        FOREIGN KEY (customer_id, enterprise_id)
            REFERENCES tb_enterprise(customer_id, enterprise_id)
);

--------------------------------------------------
-- 11. Permissões (Roles)
--------------------------------------------------
CREATE TABLE IF NOT EXISTS tb_roles (
    role_id INT GENERATED BY DEFAULT AS IDENTITY NOT NULL PRIMARY KEY,
    role_name VARCHAR(50) NOT NULL
);

--------------------------------------------------
-- 12. Relacionamento entre Usuários e Permissões
--------------------------------------------------
CREATE TABLE IF NOT EXISTS tb_users_roles (
    customer_id BIGINT NOT NULL,
    user_id INT NOT NULL,
    role_id INT NOT NULL,
    PRIMARY KEY (customer_id, user_id, role_id),
    CONSTRAINT fk_tb_users_roles_user
        FOREIGN KEY (customer_id, user_id)
            REFERENCES tb_users(customer_id, user_id),
    CONSTRAINT fk_tb_users_roles_role
        FOREIGN KEY (role_id)
            REFERENCES tb_roles(role_id)
);

--------------------------------------------------
-- 0.01 Bloco Dinâmico: Criação de triggers para atualização da coluna updated_at
--------------------------------------------------
DO $$
DECLARE
    rec RECORD;
    trigger_name TEXT;
BEGIN
    FOR rec IN
        SELECT table_schema, table_name
        FROM information_schema.columns
        WHERE column_name = 'updated_at'
          AND table_schema = 'public'
    LOOP
        trigger_name := 'trg_' || rec.table_name || '_auto_updated_at';
        -- Verifica se o trigger já existe para evitar duplicidade
        IF NOT EXISTS (
            SELECT 1 FROM pg_trigger
            WHERE tgname = trigger_name
        ) THEN
            EXECUTE format('
                CREATE TRIGGER %I
                BEFORE UPDATE ON %I.%I
                FOR EACH ROW
                EXECUTE FUNCTION update_updated_at_column();',
                trigger_name, rec.table_schema, rec.table_name);
        END IF;
    END LOOP;
END
$$;
