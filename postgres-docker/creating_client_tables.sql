--------------------------------------------------
-- 01. Tabela de clientes
--------------------------------------------------
CREATE TABLE IF NOT EXISTS tb_client (
    customer_id BIGINT NOT NULL,
    enterprise_id INT NOT NULL,
    client_id BIGINT GENERATED BY DEFAULT AS IDENTITY NOT NULL,
    first_name varchar(150) NOT NULL,
    last_name varchar(150) NULL,
    cpf_cnpj varchar(14) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (customer_id, enterprise_id, client_id),
    CONSTRAINT fk_enterprise_client
        FOREIGN KEY (customer_id, enterprise_id)
            REFERENCES tb_enterprise(customer_id, enterprise_id)
);

--------------------------------------------------
-- 02. Tabela de Fornecedores
--------------------------------------------------
CREATE TABLE IF NOT EXISTS tb_supplier (
    customer_id BIGINT NOT NULL,
    enterprise_id INT NOT NULL,
    supplier_id BIGINT GENERATED BY DEFAULT AS IDENTITY NOT NULL,
    supplier_name VARCHAR(200) NOT NULL,
    supplier_alias VARCHAR(200) NOT NULL,
    cpf_cnpj VARCHAR(14) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (customer_id, enterprise_id, supplier_id),
    CONSTRAINT fk_enterprise_supplier
        FOREIGN KEY (customer_id, enterprise_id)
            REFERENCES tb_enterprise(customer_id, enterprise_id)
);

--------------------------------------------------
-- 03. Configuração do cliente
--------------------------------------------------
CREATE TABLE IF NOT EXISTS tb_client_config (
    customer_id BIGINT NOT NULL,
    enterprise_id INT NOT NULL,
    client_id BIGINT NOT NULL,
    client_config_id INT NOT NULL,
    PRIMARY KEY (customer_id, enterprise_id, client_id, client_config_id),
    CONSTRAINT fk_client
        FOREIGN KEY (customer_id, enterprise_id, client_id)
            REFERENCES tb_client(customer_id, enterprise_id, client_id)
);

--------------------------------------------------
-- 04. Configuração do fornecedores
--------------------------------------------------
CREATE TABLE IF NOT EXISTS tb_supplier_config (
    customer_id BIGINT NOT NULL,
    enterprise_id INT NOT NULL,
    supplier_id BIGINT NOT NULL,
    supplier_config_id INT NOT NULL,
    PRIMARY KEY (customer_id, enterprise_id, supplier_id, supplier_config_id),
    CONSTRAINT fk_supplier
        FOREIGN KEY (customer_id, enterprise_id, supplier_id)
            REFERENCES tb_supplier(customer_id, enterprise_id, supplier_id)
);

