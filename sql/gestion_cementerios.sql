-- ============================================================================
-- Esquema MySQL CON LLAVES FORÁNEAS para la migración de SYSACYH (FoxPro) a MySQL
-- Generado: 2026-11-03    Tablas: 32    Motor: InnoDB    Codificación: utf8mb4
--
-- Diferencias con esquema.sql (versión sin llaves foráneas):
--  * Cada relación con coincidencia de 90% o más tiene una columna nueva <algo>_id
--    (llave foránea al id del padre) y una restricción FOREIGN KEY.
--  * El código original se conserva en su columna; la columna <algo>_id la llena
--    el script de migración y queda en NULL si el padre no existe (huérfanos).
--  * Las tablas se crean en orden: primero los padres y luego los hijos.
--  * Ninguna tabla queda sin enlace. Enlaces parciales (se llenan solo donde hay
--    coincidencia, el resto queda en NULL): oficina_id (solo códigos no repetidos entre
--    bancos), funeraria_id (por NIT) y los tres enlaces de esqueletos.
--  * Relaciones SIN llave foránea (coincidencia menor a 90%): factura de inhumados,
--    cremados y exhumados, ubicación de inhumados con inventario y exhumados.factura_in.
-- Reglas comunes: id automático, columna borrado (0 activo, 1 borrado), vistas de
-- filas activas al final, columnas COMMENT 'Dato personal' para anonimizar.
-- ============================================================================

CREATE DATABASE IF NOT EXISTS gestion_cementerios DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE gestion_cementerios;
SET NAMES utf8mb4;

-- ---------------------------------------------------------------------------
-- Catálogos
-- ---------------------------------------------------------------------------

CREATE TABLE cementerios (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  cementerio VARCHAR(2),
  nombre VARCHAR(45),
  borrado TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY idx_cementerio (cementerio)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE forma_pago (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  forma_pago VARCHAR(1),
  nombre VARCHAR(30),
  borrado TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY idx_forma_pago (forma_pago)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE bancos (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  banco VARCHAR(1),
  nombre VARCHAR(30),
  fec_acc DATETIME,
  borrado TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY idx_banco (banco)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE parentesco (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  parentesco VARCHAR(1),
  nombre VARCHAR(20),
  borrado TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY idx_parentesco (parentesco)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE tipo_id (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_orig VARCHAR(2),
  nombre VARCHAR(30),
  borrado TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY idx_id_orig (id_orig)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE tipo_serv (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  tipo_serv VARCHAR(2),
  nombre VARCHAR(20),
  borrado TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY idx_tipo_serv (tipo_serv)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE tipo_usuario (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  tipo_usuar VARCHAR(1),
  nombre VARCHAR(10),
  borrado TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY idx_tipo_usuar (tipo_usuar)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE causa_muerte (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  causa_muer VARCHAR(5),
  nombre VARCHAR(20),
  borrado TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY idx_causa_muer (causa_muer)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE estado_boveda (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  estado VARCHAR(1),
  nombre VARCHAR(30),
  borrado TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY idx_estado (estado)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE sector (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  sector VARCHAR(1),
  nombre VARCHAR(20),
  borrado TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY idx_sector (sector)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE lugar_inh (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  lugar_inh VARCHAR(1),
  nombre VARCHAR(10),
  borrado TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY idx_lugar_inh (lugar_inh)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE galerias (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  galeria VARCHAR(2),
  nombre VARCHAR(15),
  fec_acc DATETIME,
  borrado TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY idx_galeria (galeria)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE oficinas (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  bank VARCHAR(1),
  ofi VARCHAR(3),
  oficina VARCHAR(50),
  borrado TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY idx_bank_ofi (bank, ofi)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE items (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  join_orig VARCHAR(2),
  item VARCHAR(2),
  nombre VARCHAR(80),
  tabla VARCHAR(15),
  criterio VARCHAR(120),
  mitem VARCHAR(2),
  mpropietar VARCHAR(2),
  mlugar_inh VARCHAR(2),
  mtipo_usua VARCHAR(2),
  sele TINYINT(1),
  inform VARCHAR(2),
  repo VARCHAR(1),
  borrado TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY idx_item (item),
  KEY idx_join_orig (join_orig)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- Maestros de negocio
-- ---------------------------------------------------------------------------

CREATE TABLE servicios (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  servicio VARCHAR(3),
  join_orig VARCHAR(2),
  nombre VARCHAR(160),
  nombre1 VARCHAR(160),
  tipo_serv VARCHAR(2),
  valor_serv INT,
  iva DECIMAL(5,2),
  valor_iva INT,
  valor_aseo INT,
  cementerio VARCHAR(2),
  cod_contab VARCHAR(20),
  item VARCHAR(2),
  itemold VARCHAR(2),
  itemem VARCHAR(90),
  desc_orig INT,
  reporte TINYINT(1),
  cod_prod VARCHAR(8),
  des_prod VARCHAR(90),
  sub_serv VARCHAR(1),
  est_serv VARCHAR(1),
  cementerio_id INT UNSIGNED NULL COMMENT 'FK a cementerios.id (código original en cementerio)',
  tipo_serv_id INT UNSIGNED NULL COMMENT 'FK a tipo_serv.id (código original en tipo_serv)',
  item_id INT UNSIGNED NULL COMMENT 'FK a items.id (código original en item)',
  itemold_id INT UNSIGNED NULL COMMENT 'FK a items.id (código original en itemold)',
  borrado TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY idx_servicio (servicio),
  KEY idx_item (item),
  CONSTRAINT fk_servicios_cementerio_id FOREIGN KEY (cementerio_id) REFERENCES cementerios (id),
  CONSTRAINT fk_servicios_tipo_serv_id FOREIGN KEY (tipo_serv_id) REFERENCES tipo_serv (id),
  CONSTRAINT fk_servicios_item_id FOREIGN KEY (item_id) REFERENCES items (id),
  CONSTRAINT fk_servicios_itemold_id FOREIGN KEY (itemold_id) REFERENCES items (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE funerarias (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  cod_fun VARCHAR(4),
  nit VARCHAR(15),
  nombre VARCHAR(40),
  representa VARCHAR(40) COMMENT 'Dato personal',
  direccion VARCHAR(30) COMMENT 'Dato personal',
  telefono VARCHAR(40) COMMENT 'Dato personal',
  id_orig TINYINT(1),
  fec_acc DATETIME,
  disponible TINYINT(1),
  borrado TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY idx_nit (nit),
  KEY idx_cod_fun (cod_fun)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- Facturación
-- ---------------------------------------------------------------------------

CREATE TABLE factura (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  factura VARCHAR(8),
  fecha DATE,
  recibido_d VARCHAR(50) COMMENT 'Dato personal',
  nit VARCHAR(15) COMMENT 'Dato personal',
  direccion VARCHAR(30) COMMENT 'Dato personal',
  telefono VARCHAR(20) COMMENT 'Dato personal',
  fallecido VARCHAR(50) COMMENT 'Dato personal',
  forma_pago VARCHAR(1),
  valor INT,
  funeraria VARCHAR(15),
  licencia VARCHAR(6),
  cementerio VARCHAR(2),
  cementeri1 VARCHAR(2),
  sector VARCHAR(1),
  pabellon VARCHAR(5),
  galeria VARCHAR(2),
  lugar_inh VARCHAR(1),
  lugar_no VARCHAR(5),
  fila VARCHAR(2),
  anulada TINYINT(1),
  cedula VARCHAR(15) COMMENT 'Dato personal',
  fech_anul DATE,
  fec_acc DATETIME,
  cierre TINYINT(1),
  wfalle VARCHAR(50) COMMENT 'Dato personal',
  rc VARCHAR(8),
  impreso INT,
  cementerio_id INT UNSIGNED NULL COMMENT 'FK a cementerios.id (código original en cementerio)',
  forma_pago_id INT UNSIGNED NULL COMMENT 'FK a forma_pago.id (código original en forma_pago)',
  funeraria_id INT UNSIGNED NULL COMMENT 'FK a funerarias.id (código original en funeraria)',
  borrado TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY idx_factura (factura),
  KEY idx_fecha (fecha),
  KEY idx_cementerio (cementerio),
  KEY idx_forma_pago (forma_pago),
  CONSTRAINT fk_factura_cementerio_id FOREIGN KEY (cementerio_id) REFERENCES cementerios (id),
  CONSTRAINT fk_factura_forma_pago_id FOREIGN KEY (forma_pago_id) REFERENCES forma_pago (id),
  CONSTRAINT fk_factura_funeraria_id FOREIGN KEY (funeraria_id) REFERENCES funerarias (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE detalle_fact (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  factura VARCHAR(8),
  servicio VARCHAR(3),
  cantidad INT,
  valor INT,
  cementeri1 VARCHAR(2),
  dev TINYINT(1),
  fec_acc DATETIME,
  pfac BIGINT,
  factura_id INT UNSIGNED NULL COMMENT 'FK a factura.id (código original en factura)',
  servicio_id INT UNSIGNED NULL COMMENT 'FK a servicios.id (código original en servicio)',
  borrado TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY idx_factura (factura),
  KEY idx_servicio (servicio),
  CONSTRAINT fk_detalle_fact_factura_id FOREIGN KEY (factura_id) REFERENCES factura (id),
  CONSTRAINT fk_detalle_fact_servicio_id FOREIGN KEY (servicio_id) REFERENCES servicios (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE consignaciones (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  factura VARCHAR(8),
  documento VARCHAR(20),
  banco VARCHAR(1),
  fecha DATE,
  oficina VARCHAR(3),
  valor INT,
  fec_acc DATETIME,
  reg INT,
  pfac INT,
  factura_id INT UNSIGNED NULL COMMENT 'FK a factura.id (código original en factura)',
  banco_id INT UNSIGNED NULL COMMENT 'FK a bancos.id (código original en banco)',
  oficina_id INT UNSIGNED NULL COMMENT 'FK a oficinas.id (código original en oficina)',
  borrado TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY idx_factura (factura),
  KEY idx_banco (banco),
  KEY idx_fecha (fecha),
  CONSTRAINT fk_consignaciones_factura_id FOREIGN KEY (factura_id) REFERENCES factura (id),
  CONSTRAINT fk_consignaciones_banco_id FOREIGN KEY (banco_id) REFERENCES bancos (id),
  CONSTRAINT fk_consignaciones_oficina_id FOREIGN KEY (oficina_id) REFERENCES oficinas (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE efectivo (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  factura VARCHAR(8),
  valor INT,
  fec_acc DATETIME,
  factura_id INT UNSIGNED NULL COMMENT 'FK a factura.id (código original en factura)',
  borrado TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY idx_factura (factura),
  CONSTRAINT fk_efectivo_factura_id FOREIGN KEY (factura_id) REFERENCES factura (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE devoluciones (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  n_recibo VARCHAR(10),
  n_factura VARCHAR(10),
  fecha_dev DATE,
  valordev INT,
  usuario VARCHAR(10),
  fecha_pro DATETIME,
  n_factura_id INT UNSIGNED NULL COMMENT 'FK a factura.id (código original en n_factura)',
  borrado TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY idx_n_factura (n_factura),
  CONSTRAINT fk_devoluciones_n_factura_id FOREIGN KEY (n_factura_id) REFERENCES factura (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE conciliacion (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  cementerio VARCHAR(2),
  banco VARCHAR(1),
  nombre VARCHAR(30),
  fecha_cons DATE,
  documento VARCHAR(20),
  oficina VARCHAR(3),
  sucursal VARCHAR(50),
  valor_cons INT,
  factura VARCHAR(8),
  fecha_fact DATE,
  cementerio_id INT UNSIGNED NULL COMMENT 'FK a cementerios.id (código original en cementerio)',
  banco_id INT UNSIGNED NULL COMMENT 'FK a bancos.id (código original en banco)',
  borrado TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY idx_banco_documento (banco, documento),
  KEY idx_factura (factura),
  CONSTRAINT fk_conciliacion_cementerio_id FOREIGN KEY (cementerio_id) REFERENCES cementerios (id),
  CONSTRAINT fk_conciliacion_banco_id FOREIGN KEY (banco_id) REFERENCES bancos (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE rc (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  fecha DATE,
  rc INT,
  recibido_d VARCHAR(50) COMMENT 'Dato personal',
  valor BIGINT,
  valoref BIGINT,
  cedula VARCHAR(13) COMMENT 'Dato personal',
  concepto VARCHAR(2),
  descripcio TEXT,
  feccons DATE,
  valcons BIGINT,
  banco VARCHAR(1),
  colilla VARCHAR(30),
  oficina INT,
  banco_id INT UNSIGNED NULL COMMENT 'FK a bancos.id (código original en banco)',
  borrado TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY idx_rc (rc),
  CONSTRAINT fk_rc_banco_id FOREIGN KEY (banco_id) REFERENCES bancos (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- Servicios funerarios
-- ---------------------------------------------------------------------------

CREATE TABLE inhumados (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  factura VARCHAR(8),
  fecha_inh DATE,
  licencia VARCHAR(6),
  nombre VARCHAR(50) COMMENT 'Dato personal',
  cementerio VARCHAR(2),
  sector VARCHAR(1),
  pabellon VARCHAR(5),
  galeria VARCHAR(2),
  lugar_inh VARCHAR(1),
  lugar_no VARCHAR(5),
  fila VARCHAR(2),
  tipo_usuar VARCHAR(1),
  propietari VARCHAR(1),
  causa_muer VARCHAR(1),
  no_contrat VARCHAR(6),
  nombre_deu VARCHAR(50) COMMENT 'Dato personal',
  nit_deudo VARCHAR(15) COMMENT 'Dato personal',
  dir_deudo VARCHAR(30) COMMENT 'Dato personal',
  tel_deudo VARCHAR(20) COMMENT 'Dato personal',
  parentesco VARCHAR(1),
  fe_cal_exh DATE,
  edad DECIMAL(6,2),
  sexo VARCHAR(1),
  cedula VARCHAR(15) COMMENT 'Dato personal',
  tipo_id VARCHAR(2),
  cert_defun VARCHAR(15) COMMENT 'Dato personal',
  funeraria VARCHAR(15),
  fec_lic_ex DATE,
  licen_exhu VARCHAR(6),
  fec_acc DATETIME,
  reg INT,
  servicio VARCHAR(2),
  sele TINYINT(1),
  cert_crem VARCHAR(6),
  fe_cer_cre DATE,
  exp_cer_cr VARCHAR(2),
  fe_lic_inh DATE,
  exp_cer_ex VARCHAR(2),
  new_dir VARCHAR(50) COMMENT 'Dato personal',
  cierre TINYINT(1),
  email VARCHAR(45) COMMENT 'Dato personal',
  bloquea TINYINT(1),
  cementerio_id INT UNSIGNED NULL COMMENT 'FK a cementerios.id (código original en cementerio)',
  causa_muer_id INT UNSIGNED NULL COMMENT 'FK a causa_muerte.id (código original en causa_muer)',
  tipo_usuar_id INT UNSIGNED NULL COMMENT 'FK a tipo_usuario.id (código original en tipo_usuar)',
  servicio_id INT UNSIGNED NULL COMMENT 'FK a items.id (código original en servicio)',
  parentesco_id INT UNSIGNED NULL COMMENT 'FK a parentesco.id (código original en parentesco)',
  sector_id INT UNSIGNED NULL COMMENT 'FK a sector.id (código original en sector)',
  lugar_inh_id INT UNSIGNED NULL COMMENT 'FK a lugar_inh.id (código original en lugar_inh)',
  galeria_id INT UNSIGNED NULL COMMENT 'FK a galerias.id (código original en galeria)',
  tipo_identif_id INT UNSIGNED NULL COMMENT 'FK a tipo_id.id (código original en tipo_id)',
  funeraria_id INT UNSIGNED NULL COMMENT 'FK a funerarias.id (código original en funeraria)',
  borrado TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY idx_factura (factura),
  KEY idx_fecha_inh (fecha_inh),
  KEY idx_ubicacion (cementerio, sector, pabellon, galeria, lugar_inh, lugar_no, fila),
  CONSTRAINT fk_inhumados_cementerio_id FOREIGN KEY (cementerio_id) REFERENCES cementerios (id),
  CONSTRAINT fk_inhumados_causa_muer_id FOREIGN KEY (causa_muer_id) REFERENCES causa_muerte (id),
  CONSTRAINT fk_inhumados_tipo_usuar_id FOREIGN KEY (tipo_usuar_id) REFERENCES tipo_usuario (id),
  CONSTRAINT fk_inhumados_servicio_id FOREIGN KEY (servicio_id) REFERENCES items (id),
  CONSTRAINT fk_inhumados_parentesco_id FOREIGN KEY (parentesco_id) REFERENCES parentesco (id),
  CONSTRAINT fk_inhumados_sector_id FOREIGN KEY (sector_id) REFERENCES sector (id),
  CONSTRAINT fk_inhumados_lugar_inh_id FOREIGN KEY (lugar_inh_id) REFERENCES lugar_inh (id),
  CONSTRAINT fk_inhumados_galeria_id FOREIGN KEY (galeria_id) REFERENCES galerias (id),
  CONSTRAINT fk_inhumados_tipo_identif_id FOREIGN KEY (tipo_identif_id) REFERENCES tipo_id (id),
  CONSTRAINT fk_inhumados_funeraria_id FOREIGN KEY (funeraria_id) REFERENCES funerarias (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE exhumados (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  factura_ex VARCHAR(8),
  fecha_exh DATE,
  licencia_e VARCHAR(6),
  fec_lic_ex DATE,
  factura_in VARCHAR(8),
  fecha_inh DATE,
  licencia_i VARCHAR(6),
  nombre VARCHAR(50) COMMENT 'Dato personal',
  cementerio VARCHAR(2),
  sector VARCHAR(1),
  pabellon VARCHAR(5),
  galeria VARCHAR(2),
  lugar_inh VARCHAR(1),
  lugar_no VARCHAR(5),
  fila VARCHAR(2),
  tipo_usuar VARCHAR(1),
  propietari VARCHAR(1),
  causa_muer VARCHAR(1),
  no_contrat VARCHAR(6),
  nombre_deu VARCHAR(50) COMMENT 'Dato personal',
  nit_deudo VARCHAR(15) COMMENT 'Dato personal',
  dir_deudo VARCHAR(30) COMMENT 'Dato personal',
  tel_deudo VARCHAR(20) COMMENT 'Dato personal',
  parentesco VARCHAR(1),
  fe_cal_exh DATE,
  edad DECIMAL(6,2),
  sexo VARCHAR(1),
  reclamante VARCHAR(40) COMMENT 'Dato personal',
  dir_reclam VARCHAR(30) COMMENT 'Dato personal',
  tel_reclam VARCHAR(10) COMMENT 'Dato personal',
  traslado_a VARCHAR(20),
  cert_crema VARCHAR(8),
  fec_acc DATETIME,
  reg INT,
  servicio VARCHAR(2),
  servant VARCHAR(2),
  bloquea TINYINT(1),
  cementerio_id INT UNSIGNED NULL COMMENT 'FK a cementerios.id (código original en cementerio)',
  causa_muer_id INT UNSIGNED NULL COMMENT 'FK a causa_muerte.id (código original en causa_muer)',
  tipo_usuar_id INT UNSIGNED NULL COMMENT 'FK a tipo_usuario.id (código original en tipo_usuar)',
  servicio_id INT UNSIGNED NULL COMMENT 'FK a items.id (código original en servicio)',
  parentesco_id INT UNSIGNED NULL COMMENT 'FK a parentesco.id (código original en parentesco)',
  sector_id INT UNSIGNED NULL COMMENT 'FK a sector.id (código original en sector)',
  lugar_inh_id INT UNSIGNED NULL COMMENT 'FK a lugar_inh.id (código original en lugar_inh)',
  galeria_id INT UNSIGNED NULL COMMENT 'FK a galerias.id (código original en galeria)',
  borrado TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY idx_factura_ex (factura_ex),
  KEY idx_factura_in (factura_in),
  KEY idx_fecha_exh (fecha_exh),
  KEY idx_ubicacion (cementerio, sector, pabellon, galeria, lugar_inh, lugar_no, fila),
  CONSTRAINT fk_exhumados_cementerio_id FOREIGN KEY (cementerio_id) REFERENCES cementerios (id),
  CONSTRAINT fk_exhumados_causa_muer_id FOREIGN KEY (causa_muer_id) REFERENCES causa_muerte (id),
  CONSTRAINT fk_exhumados_tipo_usuar_id FOREIGN KEY (tipo_usuar_id) REFERENCES tipo_usuario (id),
  CONSTRAINT fk_exhumados_servicio_id FOREIGN KEY (servicio_id) REFERENCES items (id),
  CONSTRAINT fk_exhumados_parentesco_id FOREIGN KEY (parentesco_id) REFERENCES parentesco (id),
  CONSTRAINT fk_exhumados_sector_id FOREIGN KEY (sector_id) REFERENCES sector (id),
  CONSTRAINT fk_exhumados_lugar_inh_id FOREIGN KEY (lugar_inh_id) REFERENCES lugar_inh (id),
  CONSTRAINT fk_exhumados_galeria_id FOREIGN KEY (galeria_id) REFERENCES galerias (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE cremados (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  factura VARCHAR(8),
  fecha_cre DATE,
  certificad VARCHAR(6),
  licencia VARCHAR(6),
  nombre VARCHAR(50) COMMENT 'Dato personal',
  cementerio VARCHAR(2),
  tipo_crema VARCHAR(1),
  tipo_usuar VARCHAR(1),
  nombre_deu VARCHAR(50) COMMENT 'Dato personal',
  nit_deudo VARCHAR(15) COMMENT 'Dato personal',
  dir_deudo VARCHAR(30) COMMENT 'Dato personal',
  tel_deudo VARCHAR(20) COMMENT 'Dato personal',
  destino VARCHAR(20),
  causa_muer VARCHAR(1),
  edad DECIMAL(6,2),
  entrega_ce DATE,
  cedula VARCHAR(15) COMMENT 'Dato personal',
  cert_defun VARCHAR(15) COMMENT 'Dato personal',
  funeraria VARCHAR(15),
  sexo VARCHAR(1),
  urna TINYINT(1),
  fec_ingser DATETIME,
  tipo_id VARCHAR(2),
  fec_acc DATETIME,
  servicio VARCHAR(2),
  cierre TINYINT(1),
  emailc VARCHAR(50) COMMENT 'Dato personal',
  bloquea TINYINT(1),
  cementerio_id INT UNSIGNED NULL COMMENT 'FK a cementerios.id (código original en cementerio)',
  causa_muer_id INT UNSIGNED NULL COMMENT 'FK a causa_muerte.id (código original en causa_muer)',
  tipo_usuar_id INT UNSIGNED NULL COMMENT 'FK a tipo_usuario.id (código original en tipo_usuar)',
  servicio_id INT UNSIGNED NULL COMMENT 'FK a items.id (código original en servicio)',
  tipo_identif_id INT UNSIGNED NULL COMMENT 'FK a tipo_id.id (código original en tipo_id)',
  funeraria_id INT UNSIGNED NULL COMMENT 'FK a funerarias.id (código original en funeraria)',
  borrado TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY idx_factura (factura),
  KEY idx_fecha_cre (fecha_cre),
  KEY idx_cementerio (cementerio),
  CONSTRAINT fk_cremados_cementerio_id FOREIGN KEY (cementerio_id) REFERENCES cementerios (id),
  CONSTRAINT fk_cremados_causa_muer_id FOREIGN KEY (causa_muer_id) REFERENCES causa_muerte (id),
  CONSTRAINT fk_cremados_tipo_usuar_id FOREIGN KEY (tipo_usuar_id) REFERENCES tipo_usuario (id),
  CONSTRAINT fk_cremados_servicio_id FOREIGN KEY (servicio_id) REFERENCES items (id),
  CONSTRAINT fk_cremados_tipo_identif_id FOREIGN KEY (tipo_identif_id) REFERENCES tipo_id (id),
  CONSTRAINT fk_cremados_funeraria_id FOREIGN KEY (funeraria_id) REFERENCES funerarias (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE inhumados_nn (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  fecha_inh DATE,
  licencia VARCHAR(6),
  protocolo VARCHAR(19) COMMENT 'Dato personal',
  nombre VARCHAR(50) COMMENT 'Dato personal',
  cementerio VARCHAR(2),
  sector VARCHAR(1),
  pabellon VARCHAR(5),
  galeria VARCHAR(2),
  lugar_inh VARCHAR(1),
  lugar_no VARCHAR(5),
  fila VARCHAR(2),
  tipo_usuar VARCHAR(1),
  causa_muer VARCHAR(1),
  fe_cal_exh DATE,
  edad DECIMAL(6,2),
  sexo VARCHAR(1),
  fec_acc DATETIME,
  reg INT,
  servicio VARCHAR(2),
  cierre TINYINT(1),
  notcri VARCHAR(21) COMMENT 'Dato personal',
  certidef VARCHAR(9) COMMENT 'Dato personal',
  fecnec DATE,
  cementerio_id INT UNSIGNED NULL COMMENT 'FK a cementerios.id (código original en cementerio)',
  causa_muer_id INT UNSIGNED NULL COMMENT 'FK a causa_muerte.id (código original en causa_muer)',
  tipo_usuar_id INT UNSIGNED NULL COMMENT 'FK a tipo_usuario.id (código original en tipo_usuar)',
  servicio_id INT UNSIGNED NULL COMMENT 'FK a items.id (código original en servicio)',
  sector_id INT UNSIGNED NULL COMMENT 'FK a sector.id (código original en sector)',
  lugar_inh_id INT UNSIGNED NULL COMMENT 'FK a lugar_inh.id (código original en lugar_inh)',
  galeria_id INT UNSIGNED NULL COMMENT 'FK a galerias.id (código original en galeria)',
  borrado TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY idx_fecha_inh (fecha_inh),
  KEY idx_cementerio (cementerio),
  CONSTRAINT fk_inhumados_nn_cementerio_id FOREIGN KEY (cementerio_id) REFERENCES cementerios (id),
  CONSTRAINT fk_inhumados_nn_causa_muer_id FOREIGN KEY (causa_muer_id) REFERENCES causa_muerte (id),
  CONSTRAINT fk_inhumados_nn_tipo_usuar_id FOREIGN KEY (tipo_usuar_id) REFERENCES tipo_usuario (id),
  CONSTRAINT fk_inhumados_nn_servicio_id FOREIGN KEY (servicio_id) REFERENCES items (id),
  CONSTRAINT fk_inhumados_nn_sector_id FOREIGN KEY (sector_id) REFERENCES sector (id),
  CONSTRAINT fk_inhumados_nn_lugar_inh_id FOREIGN KEY (lugar_inh_id) REFERENCES lugar_inh (id),
  CONSTRAINT fk_inhumados_nn_galeria_id FOREIGN KEY (galeria_id) REFERENCES galerias (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE esqueletos (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  fecha DATE,
  factura VARCHAR(8),
  fec_acc DATETIME,
  inhumado_id INT UNSIGNED NULL COMMENT 'FK a inhumados.id (código original en factura)',
  exhumado_id INT UNSIGNED NULL COMMENT 'FK a exhumados.id (código original en factura)',
  cremado_id INT UNSIGNED NULL COMMENT 'FK a cremados.id (código original en factura)',
  borrado TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY idx_factura (factura),
  KEY idx_fecha (fecha),
  CONSTRAINT fk_esqueletos_inhumado_id FOREIGN KEY (inhumado_id) REFERENCES inhumados (id),
  CONSTRAINT fk_esqueletos_exhumado_id FOREIGN KEY (exhumado_id) REFERENCES exhumados (id),
  CONSTRAINT fk_esqueletos_cremado_id FOREIGN KEY (cremado_id) REFERENCES cremados (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- Inventario y propiedad
-- ---------------------------------------------------------------------------

CREATE TABLE pabellon (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  pabellon VARCHAR(5),
  nombre VARCHAR(110),
  cementerio VARCHAR(2),
  sector VARCHAR(2),
  manzana VARCHAR(3),
  lote VARCHAR(2),
  fec_acc DATETIME,
  cementerio_id INT UNSIGNED NULL COMMENT 'FK a cementerios.id (código original en cementerio)',
  borrado TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY idx_cementerio_pabellon (cementerio, pabellon),
  CONSTRAINT fk_pabellon_cementerio_id FOREIGN KEY (cementerio_id) REFERENCES cementerios (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE inventario (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  cementerio VARCHAR(2),
  sector VARCHAR(1),
  pabellon VARCHAR(5),
  galeria VARCHAR(2),
  lugar_inh VARCHAR(1),
  lugar_no VARCHAR(5),
  fila VARCHAR(2),
  tipo_usuar VARCHAR(1),
  propietari VARCHAR(1),
  disponible TINYINT(1),
  estado VARCHAR(1),
  activado TINYINT(1),
  fec_acc DATETIME,
  cementerio_id INT UNSIGNED NULL COMMENT 'FK a cementerios.id (código original en cementerio)',
  pabellon_id INT UNSIGNED NULL COMMENT 'FK a pabellon.id (código original en cementerio+pabellon)',
  estado_id INT UNSIGNED NULL COMMENT 'FK a estado_boveda.id (código original en estado)',
  borrado TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY idx_ubicacion (cementerio, sector, pabellon, galeria, lugar_inh, lugar_no, fila),
  KEY idx_cementerio_pabellon (cementerio, pabellon),
  CONSTRAINT fk_inventario_cementerio_id FOREIGN KEY (cementerio_id) REFERENCES cementerios (id),
  CONSTRAINT fk_inventario_pabellon_id FOREIGN KEY (pabellon_id) REFERENCES pabellon (id),
  CONSTRAINT fk_inventario_estado_id FOREIGN KEY (estado_id) REFERENCES estado_boveda (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE prop_lotes (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  cementerio VARCHAR(2),
  sector VARCHAR(2),
  subsector VARCHAR(2),
  manzana VARCHAR(3),
  lote VARCHAR(3),
  mausoleo VARCHAR(71),
  tipo_cons VARCHAR(9),
  maus_statu VARCHAR(1),
  lote_area INT,
  bov_rotu INT,
  bov_lapi INT,
  bov_blan INT,
  bov_vaci INT,
  bov_total INT,
  osa_rot INT,
  osa_lap INT,
  osa_blan INT,
  osa_vacio INT,
  osa_tot INT,
  cen_rot INT,
  cen_lap INT,
  cen_blan INT,
  cen_vacio INT,
  cen_tot INT,
  copi_escr TINYINT(1),
  copi_cert TINYINT(1),
  codigo VARCHAR(5),
  folio INT,
  foto TEXT,
  bo_rot INT,
  bo_lap INT,
  bo_blan INT,
  bo_vacio INT,
  bov_sin INT,
  bo_tot INT,
  osa_sin INT,
  cen_sin INT,
  cementerio_id INT UNSIGNED NULL COMMENT 'FK a cementerios.id (código original en cementerio)',
  borrado TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY idx_cementerio_subsector_manzana_lote (cementerio, subsector, manzana, lote),
  CONSTRAINT fk_prop_lotes_cementerio_id FOREIGN KEY (cementerio_id) REFERENCES cementerios (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE prop_unidades (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  cementerio VARCHAR(2),
  sector VARCHAR(2),
  subsector VARCHAR(2),
  manzana VARCHAR(3),
  lote VARCHAR(3),
  tipo_cons VARCHAR(9),
  maus_statu VARCHAR(1),
  galeria VARCHAR(7),
  lugar_no VARCHAR(8),
  fila VARCHAR(4),
  copi_escr TINYINT(1),
  copi_cert TINYINT(1),
  prop_nit VARCHAR(17) COMMENT 'Dato personal',
  prop_nombr VARCHAR(101) COMMENT 'Dato personal',
  observacio VARCHAR(72),
  inhumado VARCHAR(50) COMMENT 'Dato personal',
  fecha_inh DATE,
  lugar_inh VARCHAR(1),
  estado VARCHAR(1),
  cementerio_id INT UNSIGNED NULL COMMENT 'FK a cementerios.id (código original en cementerio)',
  prop_lote_id INT UNSIGNED NULL COMMENT 'FK a prop_lotes.id (código original en cementerio+subsector+manzana+lote)',
  borrado TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY idx_cementerio_subsector_manzana_lote (cementerio, subsector, manzana, lote),
  CONSTRAINT fk_prop_unidades_cementerio_id FOREIGN KEY (cementerio_id) REFERENCES cementerios (id),
  CONSTRAINT fk_prop_unidades_prop_lote_id FOREIGN KEY (prop_lote_id) REFERENCES prop_lotes (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- Vistas de filas activas
-- ---------------------------------------------------------------------------

CREATE VIEW v_cementerios_activos AS SELECT * FROM cementerios WHERE borrado = 0;
CREATE VIEW v_forma_pago_activos AS SELECT * FROM forma_pago WHERE borrado = 0;
CREATE VIEW v_bancos_activos AS SELECT * FROM bancos WHERE borrado = 0;
CREATE VIEW v_parentesco_activos AS SELECT * FROM parentesco WHERE borrado = 0;
CREATE VIEW v_tipo_id_activos AS SELECT * FROM tipo_id WHERE borrado = 0;
CREATE VIEW v_tipo_serv_activos AS SELECT * FROM tipo_serv WHERE borrado = 0;
CREATE VIEW v_tipo_usuario_activos AS SELECT * FROM tipo_usuario WHERE borrado = 0;
CREATE VIEW v_causa_muerte_activos AS SELECT * FROM causa_muerte WHERE borrado = 0;
CREATE VIEW v_estado_boveda_activos AS SELECT * FROM estado_boveda WHERE borrado = 0;
CREATE VIEW v_sector_activos AS SELECT * FROM sector WHERE borrado = 0;
CREATE VIEW v_lugar_inh_activos AS SELECT * FROM lugar_inh WHERE borrado = 0;
CREATE VIEW v_galerias_activos AS SELECT * FROM galerias WHERE borrado = 0;
CREATE VIEW v_oficinas_activos AS SELECT * FROM oficinas WHERE borrado = 0;
CREATE VIEW v_items_activos AS SELECT * FROM items WHERE borrado = 0;
CREATE VIEW v_servicios_activos AS SELECT * FROM servicios WHERE borrado = 0;
CREATE VIEW v_funerarias_activos AS SELECT * FROM funerarias WHERE borrado = 0;
CREATE VIEW v_factura_activos AS SELECT * FROM factura WHERE borrado = 0;
CREATE VIEW v_detalle_fact_activos AS SELECT * FROM detalle_fact WHERE borrado = 0;
CREATE VIEW v_consignaciones_activos AS SELECT * FROM consignaciones WHERE borrado = 0;
CREATE VIEW v_efectivo_activos AS SELECT * FROM efectivo WHERE borrado = 0;
CREATE VIEW v_devoluciones_activos AS SELECT * FROM devoluciones WHERE borrado = 0;
CREATE VIEW v_conciliacion_activos AS SELECT * FROM conciliacion WHERE borrado = 0;
CREATE VIEW v_rc_activos AS SELECT * FROM rc WHERE borrado = 0;
CREATE VIEW v_inhumados_activos AS SELECT * FROM inhumados WHERE borrado = 0;
CREATE VIEW v_exhumados_activos AS SELECT * FROM exhumados WHERE borrado = 0;
CREATE VIEW v_cremados_activos AS SELECT * FROM cremados WHERE borrado = 0;
CREATE VIEW v_inhumados_nn_activos AS SELECT * FROM inhumados_nn WHERE borrado = 0;
CREATE VIEW v_esqueletos_activos AS SELECT * FROM esqueletos WHERE borrado = 0;
CREATE VIEW v_pabellon_activos AS SELECT * FROM pabellon WHERE borrado = 0;
CREATE VIEW v_inventario_activos AS SELECT * FROM inventario WHERE borrado = 0;
CREATE VIEW v_prop_lotes_activos AS SELECT * FROM prop_lotes WHERE borrado = 0;
CREATE VIEW v_prop_unidades_activos AS SELECT * FROM prop_unidades WHERE borrado = 0;

USE gestion_cementerios;
SELECT * FROM cementerios;

SELECT * FROM causa_muerte;
SELECT 'estado_boveda' AS tabla, COUNT(*) AS registros FROM estado_boveda
UNION ALL SELECT 'forma_pago', COUNT(*) FROM forma_pago
UNION ALL SELECT 'lugar_inh', COUNT(*) FROM lugar_inh
UNION ALL SELECT 'parentesco', COUNT(*) FROM parentesco
UNION ALL SELECT 'sector', COUNT(*) FROM sector
UNION ALL SELECT 'tipo_serv', COUNT(*) FROM tipo_serv
UNION ALL SELECT 'tipo_usuario', COUNT(*) FROM tipo_usuario
UNION ALL SELECT 'oficinas', COUNT(*) FROM oficinas;


SELECT * FROM bancos;
SELECT * FROM tipo_id;
SELECT banco, nombre, fec_acc FROM bancos ORDER BY banco;

SELECT COUNT(*) FROM bancos;
SELECT * FROM tipo_id;


SELECT cementerio_id, cementerio, COUNT(*) AS total
FROM pabellon
GROUP BY cementerio_id, cementerio
ORDER BY cementerio_id;

SELECT COUNT(*) FROM pabellon;

SELECT cod_fun, nombre, direccion
FROM funerarias
WHERE direccion LIKE '%º%' OR direccion LIKE '%á%'
ORDER BY nombre
LIMIT 20;

SELECT COUNT(*) AS con_caracteres_raros
FROM funerarias
WHERE direccion LIKE '%§%' OR direccion LIKE '%ß%'
OR nombre LIKE '%§%' OR nombre LIKE '%ß%';
SELECT COUNT(*) FROM pabellon WHERE nombre LIKE '%§%' OR nombre LIKE '%ß%' OR nombre LIKE '%¤%';


DESCRIBE oficinas;
SELECT * FROM oficinas LIMIT 10;

SELECT COUNT(*) FROM oficinas WHERE oficina LIKE '%§%' OR oficina LIKE '%ß%' OR oficina LIKE '%¤%';

SELECT * FROM galerias;
SELECT item, join_orig, nombre, sele FROM items ORDER BY item LIMIT 20;
SELECT item, COUNT(*) AS veces FROM items GROUP BY item HAVING COUNT(*) > 1;


SELECT COUNT(*) AS total,
       SUM(cementerio_id IS NULL) AS sin_cementerio,
       SUM(tipo_serv_id IS NULL) AS sin_tipo_serv,
       SUM(item_id IS NULL) AS sin_item,
       SUM(itemold_id IS NULL) AS sin_itemold
FROM servicios;

SELECT borrado, COUNT(*) FROM servicios GROUP BY borrado;
USE gestion_cementerios;
DELETE FROM servicios WHERE id > 0;

SELECT COUNT(*) FROM servicios;

SELECT 'estado_boveda' AS tabla, SUM(borrado=0) AS activas, SUM(borrado=1) AS borradas FROM estado_boveda
UNION ALL SELECT 'lugar_inh', SUM(borrado=0), SUM(borrado=1) FROM lugar_inh
UNION ALL SELECT 'sector', SUM(borrado=0), SUM(borrado=1) FROM sector
UNION ALL SELECT 'oficinas', SUM(borrado=0), SUM(borrado=1) FROM oficinas
UNION ALL SELECT 'bancos', SUM(borrado=0), SUM(borrado=1) FROM bancos
UNION ALL SELECT 'galerias', SUM(borrado=0), SUM(borrado=1) FROM galerias
UNION ALL SELECT 'items', SUM(borrado=0), SUM(borrado=1) FROM items
UNION ALL SELECT 'funerarias', SUM(borrado=0), SUM(borrado=1) FROM funerarias
UNION ALL SELECT 'servicios', SUM(borrado=0), SUM(borrado=1) FROM servicios
UNION ALL SELECT 'pabellon', SUM(borrado=0), SUM(borrado=1) FROM pabellon;



SELECT SUM(a) AS activas, SUM(b) AS borradas FROM (
SELECT SUM(borrado=0) a, SUM(borrado=1) b FROM bancos
UNION ALL SELECT SUM(borrado=0), SUM(borrado=1) FROM causa_muerte
UNION ALL SELECT SUM(borrado=0), SUM(borrado=1) FROM cementerios
UNION ALL SELECT SUM(borrado=0), SUM(borrado=1) FROM estado_boveda
UNION ALL SELECT SUM(borrado=0), SUM(borrado=1) FROM forma_pago
UNION ALL SELECT SUM(borrado=0), SUM(borrado=1) FROM galerias
UNION ALL SELECT SUM(borrado=0), SUM(borrado=1) FROM items
UNION ALL SELECT SUM(borrado=0), SUM(borrado=1) FROM lugar_inh
UNION ALL SELECT SUM(borrado=0), SUM(borrado=1) FROM oficinas
UNION ALL SELECT SUM(borrado=0), SUM(borrado=1) FROM parentesco
UNION ALL SELECT SUM(borrado=0), SUM(borrado=1) FROM sector
UNION ALL SELECT SUM(borrado=0), SUM(borrado=1) FROM tipo_id
UNION ALL SELECT SUM(borrado=0), SUM(borrado=1) FROM tipo_serv
UNION ALL SELECT SUM(borrado=0), SUM(borrado=1) FROM tipo_usuario
UNION ALL SELECT SUM(borrado=0), SUM(borrado=1) FROM consignaciones
UNION ALL SELECT SUM(borrado=0), SUM(borrado=1) FROM cremados
UNION ALL SELECT SUM(borrado=0), SUM(borrado=1) FROM detalle_fact
UNION ALL SELECT SUM(borrado=0), SUM(borrado=1) FROM exhumados
UNION ALL SELECT SUM(borrado=0), SUM(borrado=1) FROM factura
UNION ALL SELECT SUM(borrado=0), SUM(borrado=1) FROM funerarias
UNION ALL SELECT SUM(borrado=0), SUM(borrado=1) FROM inhumados
UNION ALL SELECT SUM(borrado=0), SUM(borrado=1) FROM inventario
UNION ALL SELECT SUM(borrado=0), SUM(borrado=1) FROM pabellon
UNION ALL SELECT SUM(borrado=0), SUM(borrado=1) FROM servicios
UNION ALL SELECT SUM(borrado=0), SUM(borrado=1) FROM conciliacion
UNION ALL SELECT SUM(borrado=0), SUM(borrado=1) FROM devoluciones
UNION ALL SELECT SUM(borrado=0), SUM(borrado=1) FROM efectivo
UNION ALL SELECT SUM(borrado=0), SUM(borrado=1) FROM esqueletos
UNION ALL SELECT SUM(borrado=0), SUM(borrado=1) FROM inhumados_nn
UNION ALL SELECT SUM(borrado=0), SUM(borrado=1) FROM prop_lotes
UNION ALL SELECT SUM(borrado=0), SUM(borrado=1) FROM prop_unidades
UNION ALL SELECT SUM(borrado=0), SUM(borrado=1) FROM rc
) t;


SELECT LENGTH(oficina) AS largo,
       COUNT(*) AS filas,
       SUM(oficina LIKE '%.%') AS con_punto,
       MIN(oficina) AS ejemplo_menor,
       MAX(oficina) AS ejemplo_mayor
FROM consignaciones
GROUP BY LENGTH(oficina)
ORDER BY largo;

SELECT REPLACE(oficina, '.', '') AS valor, COUNT(*) AS filas
FROM consignaciones
WHERE oficina IS NOT NULL
  AND REPLACE(oficina, '.', '') NOT REGEXP '^[0-9]+$'
GROUP BY REPLACE(oficina, '.', '')
ORDER BY filas DESC
LIMIT 30;

UPDATE consignaciones
SET oficina = CASE
    WHEN REPLACE(oficina, '.', '') REGEXP '^[0-9]+$'
        THEN LPAD(REPLACE(oficina, '.', ''), 3, '0')
    WHEN REPLACE(oficina, '.', '') IN ('POP', 'OCC', 'CAV', 'AHS')
        THEN UPPER(REPLACE(oficina, '.', ''))
    ELSE NULL
END
WHERE id > 0 AND oficina IS NOT NULL;

SELECT LENGTH(oficina) AS largo, COUNT(*) AS filas
FROM consignaciones
GROUP BY LENGTH(oficina)
ORDER BY largo;

SELECT 'inhumados.fecha_inh' AS campo, MIN(fecha_inh) AS minimo, MAX(fecha_inh) AS maximo, SUM(fecha_inh = '1900-01-01') AS en_1900 FROM inhumados
UNION ALL SELECT 'cremados.fecha_cre', MIN(fecha_cre), MAX(fecha_cre), SUM(fecha_cre = '1900-01-01') FROM cremados
UNION ALL SELECT 'exhumados.fecha_exh', MIN(fecha_exh), MAX(fecha_exh), SUM(fecha_exh = '1900-01-01') FROM exhumados
UNION ALL SELECT 'factura.fecha', MIN(fecha), MAX(fecha), SUM(fecha = '1900-01-01') FROM factura
UNION ALL SELECT 'consignaciones.fecha', MIN(fecha), MAX(fecha), SUM(fecha = '1900-01-01') FROM consignaciones
UNION ALL SELECT 'rc.fecha', MIN(fecha), MAX(fecha), SUM(fecha = '1900-01-01') FROM rc;

SELECT 'inhumados' AS tabla, YEAR(fecha_inh) AS anio, COUNT(*) AS filas
FROM inhumados
WHERE fecha_inh < '2001-01-01' OR fecha_inh > '2023-06-01'
GROUP BY YEAR(fecha_inh)
UNION ALL
SELECT 'exhumados', YEAR(fecha_exh), COUNT(*)
FROM exhumados
WHERE fecha_exh < '2001-01-01' OR fecha_exh > '2023-06-01'
GROUP BY YEAR(fecha_exh)
ORDER BY 1, 2;

UPDATE inhumados
SET fecha_inh = NULL
WHERE id > 0 AND (fecha_inh < '1901-01-01' OR fecha_inh > '2023-06-01');

UPDATE exhumados
SET fecha_exh = NULL
WHERE id > 0 AND fecha_exh < '1901-01-01';

SELECT 'inhumados' AS tabla, MIN(fecha_inh) AS minimo, MAX(fecha_inh) AS maximo, SUM(fecha_inh IS NULL) AS vacias FROM inhumados
UNION ALL SELECT 'exhumados', MIN(fecha_exh), MAX(fecha_exh), SUM(fecha_exh IS NULL) FROM exhumados;

SELECT COUNT(*) AS sobrantes
FROM (
  SELECT ROW_NUMBER() OVER (
           PARTITION BY factura, servicio, cantidad, valor, cementeri1, dev, fec_acc, pfac
           ORDER BY id) AS n
  FROM detalle_fact
  WHERE borrado = 0
) t
WHERE n > 1;



DELETE d
FROM detalle_fact d
JOIN (
  SELECT id
  FROM (
    SELECT id,
           ROW_NUMBER() OVER (
             PARTITION BY factura, servicio, cantidad, valor, cementeri1, dev, fec_acc, pfac
             ORDER BY id) AS n
    FROM detalle_fact
    WHERE borrado = 0
  ) t
  WHERE n > 1
) x ON x.id = d.id
WHERE d.id > 0;

SELECT COUNT(*) AS activas FROM detalle_fact WHERE borrado = 0;


-- 1. Contar sobrantes (debe dar 809)
SELECT COUNT(*) AS sobrantes FROM (
  SELECT id, ROW_NUMBER() OVER (
           PARTITION BY fecha, factura, fec_acc
           ORDER BY id) AS n
  FROM esqueletos
  WHERE borrado = 0
) t WHERE n > 1;



-- 2. Respaldo
CREATE TABLE esqueletos_bak AS SELECT * FROM esqueletos;

-- 3. Borrar duplicados
DELETE e
FROM esqueletos e
JOIN (
  SELECT id
  FROM (
    SELECT id,
           ROW_NUMBER() OVER (
             PARTITION BY fecha, factura, fec_acc
             ORDER BY id) AS n
    FROM esqueletos
    WHERE borrado = 0
  ) t
  WHERE n > 1
) x ON x.id = e.id
WHERE e.id > 0;

-- 4. Verificar
SELECT COUNT(*) AS sobrantes FROM (
  SELECT id, ROW_NUMBER() OVER (
           PARTITION BY fecha, factura, fec_acc
           ORDER BY id) AS n
  FROM esqueletos
  WHERE borrado = 0
) t WHERE n > 1;




-- 1. Contar sobrantes (debe dar 297)
SELECT COUNT(*) AS sobrantes FROM (
  SELECT id, ROW_NUMBER() OVER (
           PARTITION BY cementerio, sector, subsector, manzana, lote, tipo_cons,
                        maus_statu, galeria, lugar_no, fila, copi_escr, copi_cert,
                        prop_nit, prop_nombr, observacio, inhumado, fecha_inh,
                        lugar_inh, estado
           ORDER BY id) AS n
  FROM prop_unidades
  WHERE borrado = 0
) t WHERE n > 1;






-- 2. Respaldo
CREATE TABLE prop_unidades_bak AS SELECT * FROM prop_unidades;

-- 3. Borrar duplicados
DELETE p
FROM prop_unidades p
JOIN (
  SELECT id
  FROM (
    SELECT id,
           ROW_NUMBER() OVER (
             PARTITION BY cementerio, sector, subsector, manzana, lote, tipo_cons,
                          maus_statu, galeria, lugar_no, fila, copi_escr, copi_cert,
                          prop_nit, prop_nombr, observacio, inhumado, fecha_inh,
                          lugar_inh, estado
             ORDER BY id) AS n
    FROM prop_unidades
    WHERE borrado = 0
  ) t
  WHERE n > 1
) x ON x.id = p.id
WHERE p.id > 0;

-- 4. Verificar
SELECT COUNT(*) AS activas FROM prop_unidades WHERE borrado = 0;

-- 1. Contar sobrantes (debe dar 182)
SELECT COUNT(*) AS sobrantes FROM (
  SELECT id, ROW_NUMBER() OVER (
           PARTITION BY cementerio, sector, pabellon, galeria, lugar_inh, lugar_no,
                        fila, tipo_usuar, propietari, disponible, estado, activado,
                        fec_acc
           ORDER BY id) AS n
  FROM inventario
  WHERE borrado = 0
) t WHERE n > 1;


-- 2. Respaldo
CREATE TABLE inventario_bak AS SELECT * FROM inventario;

-- 3. Borrar duplicados
DELETE i
FROM inventario i
JOIN (
  SELECT id
  FROM (
    SELECT id,
           ROW_NUMBER() OVER (
             PARTITION BY cementerio, sector, pabellon, galeria, lugar_inh, lugar_no,
                          fila, tipo_usuar, propietari, disponible, estado, activado,
                          fec_acc
             ORDER BY id) AS n
    FROM inventario
    WHERE borrado = 0
  ) t
  WHERE n > 1
) x ON x.id = i.id
WHERE i.id > 0;

-- 4. Verificar
SELECT COUNT(*) AS activas FROM inventario WHERE borrado = 0;


-- 1. Contar sobrantes (debe dar 23)
SELECT COUNT(*) AS sobrantes FROM (
  SELECT id, ROW_NUMBER() OVER (
           PARTITION BY fecha_inh, licencia, protocolo, nombre, cementerio, sector,
                        pabellon, galeria, lugar_inh, lugar_no, fila, tipo_usuar,
                        causa_muer, fe_cal_exh, edad, sexo, fec_acc, reg, servicio,
                        cierre, notcri, certidef, fecnec
           ORDER BY id) AS n
  FROM inhumados_nn
  WHERE borrado = 0
) t WHERE n > 1;


-- 2. Respaldo
CREATE TABLE inhumados_nn_bak AS SELECT * FROM inhumados_nn;

-- 3. Borrar duplicados
DELETE n
FROM inhumados_nn n
JOIN (
  SELECT id
  FROM (
    SELECT id,
           ROW_NUMBER() OVER (
             PARTITION BY fecha_inh, licencia, protocolo, nombre, cementerio, sector,
                          pabellon, galeria, lugar_inh, lugar_no, fila, tipo_usuar,
                          causa_muer, fe_cal_exh, edad, sexo, fec_acc, reg, servicio,
                          cierre, notcri, certidef, fecnec
             ORDER BY id) AS rn
    FROM inhumados_nn
    WHERE borrado = 0
  ) t
  WHERE rn > 1
) x ON x.id = n.id
WHERE n.id > 0;

-- 4. Verificar
SELECT COUNT(*) AS activas FROM inhumados_nn WHERE borrado = 0;


-- 1. Contar sobrantes (debe dar 17)
SELECT COUNT(*) AS sobrantes FROM (
  SELECT id, ROW_NUMBER() OVER (
           PARTITION BY factura, fecha_cre, certificad, licencia, nombre, cementerio,
                        tipo_crema, tipo_usuar, nombre_deu, nit_deudo, dir_deudo,
                        tel_deudo, destino, causa_muer, edad, entrega_ce, cedula,
                        cert_defun, funeraria, sexo, urna, fec_ingser, tipo_id,
                        fec_acc, servicio, cierre, emailc, bloquea
           ORDER BY id) AS rn
  FROM cremados
  WHERE borrado = 0
) t WHERE rn > 1;
 

-- 2. Respaldo
CREATE TABLE cremados_bak AS SELECT * FROM cremados;

-- 3. Borrar duplicados
DELETE c
FROM cremados c
JOIN (
  SELECT id
  FROM (
    SELECT id,
           ROW_NUMBER() OVER (
             PARTITION BY factura, fecha_cre, certificad, licencia, nombre, cementerio,
                          tipo_crema, tipo_usuar, nombre_deu, nit_deudo, dir_deudo,
                          tel_deudo, destino, causa_muer, edad, entrega_ce, cedula,
                          cert_defun, funeraria, sexo, urna, fec_ingser, tipo_id,
                          fec_acc, servicio, cierre, emailc, bloquea
             ORDER BY id) AS rn
    FROM cremados
    WHERE borrado = 0
  ) t
  WHERE rn > 1
) x ON x.id = c.id
WHERE c.id > 0;

-- 4. Verificar
SELECT COUNT(*) AS activas FROM cremados WHERE borrado = 0;


-- 1. Contar sobrantes (debe dar 7)
SELECT COUNT(*) AS sobrantes FROM (
  SELECT id, ROW_NUMBER() OVER (
           PARTITION BY factura, fecha_inh, licencia, nombre, cementerio, sector,
                        pabellon, galeria, lugar_inh, lugar_no, fila, tipo_usuar,
                        propietari, causa_muer, no_contrat, nombre_deu, nit_deudo,
                        dir_deudo, tel_deudo, parentesco, fe_cal_exh, edad, sexo,
                        cedula, tipo_id, cert_defun, funeraria, fec_lic_ex,
                        licen_exhu, fec_acc, reg, servicio, sele, cert_crem,
                        fe_cer_cre, exp_cer_cr, fe_lic_inh, exp_cer_ex, new_dir,
                        cierre, email, bloquea
           ORDER BY id) AS rn
  FROM inhumados
  WHERE borrado = 0
) t WHERE rn > 1;


-- 2. Respaldo
CREATE TABLE inhumados_bak AS SELECT * FROM inhumados;

-- 3. Borrar duplicados
DELETE h
FROM inhumados h
JOIN (
  SELECT id
  FROM (
    SELECT id,
           ROW_NUMBER() OVER (
             PARTITION BY factura, fecha_inh, licencia, nombre, cementerio, sector,
                          pabellon, galeria, lugar_inh, lugar_no, fila, tipo_usuar,
                          propietari, causa_muer, no_contrat, nombre_deu, nit_deudo,
                          dir_deudo, tel_deudo, parentesco, fe_cal_exh, edad, sexo,
                          cedula, tipo_id, cert_defun, funeraria, fec_lic_ex,
                          licen_exhu, fec_acc, reg, servicio, sele, cert_crem,
                          fe_cer_cre, exp_cer_cr, fe_lic_inh, exp_cer_ex, new_dir,
                          cierre, email, bloquea
             ORDER BY id) AS rn
    FROM inhumados
    WHERE borrado = 0
  ) t
  WHERE rn > 1
) x ON x.id = h.id
WHERE h.id > 0;

-- 4. Verificar
SELECT COUNT(*) AS activas FROM inhumados WHERE borrado = 0;



-- Respaldos
CREATE TABLE efectivo_bak    AS SELECT * FROM efectivo;
CREATE TABLE items_bak       AS SELECT * FROM items;
CREATE TABLE oficinas_bak    AS SELECT * FROM oficinas;
CREATE TABLE prop_lotes_bak  AS SELECT * FROM prop_lotes;

-- efectivo
DELETE t FROM efectivo t
JOIN (
  SELECT id FROM (
    SELECT id, ROW_NUMBER() OVER (
             PARTITION BY factura, valor, fec_acc ORDER BY id) AS rn
    FROM efectivo WHERE borrado = 0
  ) x WHERE rn > 1
) d ON d.id = t.id
WHERE t.id > 0;

-- items
DELETE t FROM items t
JOIN (
  SELECT id FROM (
    SELECT id, ROW_NUMBER() OVER (
             PARTITION BY join_orig, item, nombre, tabla, criterio, mitem,
                          mpropietar, mlugar_inh, mtipo_usua, sele, inform, repo
             ORDER BY id) AS rn
    FROM items WHERE borrado = 0
  ) x WHERE rn > 1
) d ON d.id = t.id
WHERE t.id > 0;

-- oficinas
DELETE t FROM oficinas t
JOIN (
  SELECT id FROM (
    SELECT id, ROW_NUMBER() OVER (
             PARTITION BY bank, ofi, oficina ORDER BY id) AS rn
    FROM oficinas WHERE borrado = 0
  ) x WHERE rn > 1
) d ON d.id = t.id
WHERE t.id > 0;

-- prop_lotes
DELETE t FROM prop_lotes t
JOIN (
  SELECT id FROM (
    SELECT id, ROW_NUMBER() OVER (
             PARTITION BY cementerio, sector, subsector, manzana, lote, mausoleo,
                          tipo_cons, maus_statu, lote_area, bov_rotu, bov_lapi,
                          bov_blan, bov_vaci, bov_total, osa_rot, osa_lap, osa_blan,
                          osa_vacio, osa_tot, cen_rot, cen_lap, cen_blan, cen_vacio,
                          cen_tot, copi_escr, copi_cert, codigo, folio, foto,
                          bo_rot, bo_lap, bo_blan, bo_vacio, bov_sin, bo_tot,
                          osa_sin, cen_sin
             ORDER BY id) AS rn
    FROM prop_lotes WHERE borrado = 0
  ) x WHERE rn > 1
) d ON d.id = t.id
WHERE t.id > 0;

-- Verificación
SELECT 'efectivo'   AS tabla, COUNT(*) AS activas FROM efectivo   WHERE borrado = 0
UNION ALL SELECT 'items',      COUNT(*) FROM items      WHERE borrado = 0
UNION ALL SELECT 'oficinas',   COUNT(*) FROM oficinas   WHERE borrado = 0
UNION ALL SELECT 'prop_lotes', COUNT(*) FROM prop_lotes WHERE borrado = 0;



SELECT forma_pago, nombre FROM forma_pago;
SELECT cementerio, nombre FROM cementerios;

SELECT 'factura.forma_pago' AS columna, f.forma_pago AS codigo, COUNT(*) AS filas
FROM factura f
WHERE f.forma_pago IS NOT NULL AND f.forma_pago NOT REGEXP '^[A-Za-z0-9]+$'
  AND NOT EXISTS (SELECT 1 FROM forma_pago c WHERE c.forma_pago = f.forma_pago)
GROUP BY f.forma_pago
UNION ALL
SELECT 'exhumados.cementerio', e.cementerio, COUNT(*)
FROM exhumados e
WHERE e.cementerio IS NOT NULL AND e.cementerio NOT REGEXP '^[A-Za-z0-9]+$'
  AND NOT EXISTS (SELECT 1 FROM cementerios c WHERE c.cementerio = e.cementerio)
GROUP BY e.cementerio
UNION ALL
SELECT 'exhumados.sector', e.sector, COUNT(*)
FROM exhumados e
WHERE e.sector IS NOT NULL AND e.sector NOT REGEXP '^[A-Za-z0-9]+$'
  AND NOT EXISTS (SELECT 1 FROM sector c WHERE c.sector = e.sector)
GROUP BY e.sector
UNION ALL
SELECT 'inhumados.servicio', i.servicio, COUNT(*)
FROM inhumados i
WHERE i.servicio IS NOT NULL AND i.servicio NOT REGEXP '^[A-Za-z0-9]+$'
  AND NOT EXISTS (SELECT 1 FROM items c WHERE c.item = i.servicio)
GROUP BY i.servicio;

SELECT forma_pago, nombre FROM forma_pago;
SELECT cementerio, nombre FROM cementerios;


UPDATE factura f SET f.forma_pago = NULL
WHERE f.id > 0 AND f.forma_pago IS NOT NULL AND f.forma_pago NOT REGEXP '^[A-Za-z0-9]+$'
  AND NOT EXISTS (SELECT 1 FROM forma_pago c WHERE c.forma_pago = f.forma_pago);

UPDATE exhumados e SET e.cementerio = NULL
WHERE e.id > 0 AND e.cementerio IS NOT NULL AND e.cementerio NOT REGEXP '^[A-Za-z0-9]+$'
  AND NOT EXISTS (SELECT 1 FROM cementerios c WHERE c.cementerio = e.cementerio);

UPDATE exhumados e SET e.sector = NULL
WHERE e.id > 0 AND e.sector IS NOT NULL AND e.sector NOT REGEXP '^[A-Za-z0-9]+$'
  AND NOT EXISTS (SELECT 1 FROM sector c WHERE c.sector = e.sector);

UPDATE inhumados i SET i.servicio = NULL
WHERE i.id > 0 AND i.servicio IS NOT NULL AND i.servicio NOT REGEXP '^[A-Za-z0-9]+$'
  AND NOT EXISTS (SELECT 1 FROM items c WHERE c.item = i.servicio);
  
  
  
SELECT 'factura' AS tabla, cementerio, COUNT(*) AS filas
FROM factura WHERE borrado = 0 AND cementerio = 'o' GROUP BY cementerio
UNION ALL
SELECT 'prop_lotes', cementerio, COUNT(*)
FROM prop_lotes WHERE borrado = 0 AND cementerio = 'IR' GROUP BY cementerio;


UPDATE factura SET cementerio = NULL
WHERE id > 0 AND cementerio = 'o'
  AND NOT EXISTS (SELECT 1 FROM cementerios c WHERE c.cementerio = factura.cementerio);

UPDATE prop_lotes SET cementerio = NULL
WHERE id > 0 AND cementerio = 'IR'
  AND NOT EXISTS (SELECT 1 FROM cementerios c WHERE c.cementerio = prop_lotes.cementerio);
  
  
  
  
  
  
  SELECT 'factura' AS padre, COUNT(*) AS codigos_repetidos FROM (
  SELECT factura FROM factura WHERE borrado = 0 AND factura IS NOT NULL
  GROUP BY factura HAVING COUNT(*) > 1) x
UNION ALL
SELECT 'servicios', COUNT(*) FROM (
  SELECT servicio FROM servicios WHERE borrado = 0 AND servicio IS NOT NULL
  GROUP BY servicio HAVING COUNT(*) > 1) x;
  
  
  
  
-- Facturas con código repetido (23 códigos)
SELECT f.id, f.factura, f.fecha, f.cementerio, f.forma_pago
FROM factura f
JOIN (SELECT factura FROM factura
      WHERE borrado = 0 AND factura IS NOT NULL
      GROUP BY factura HAVING COUNT(*) > 1) r ON r.factura = f.factura
WHERE f.borrado = 0
ORDER BY f.factura, f.id;

-- Servicio con código repetido (1 código)
SELECT s.*
FROM servicios s
JOIN (SELECT servicio FROM servicios
      WHERE borrado = 0 AND servicio IS NOT NULL
      GROUP BY servicio HAVING COUNT(*) > 1) r ON r.servicio = s.servicio
WHERE s.borrado = 0
ORDER BY s.servicio, s.id;



SELECT f.factura, COUNT(*) AS filas,
  CONCAT_WS(', ',
    IF(COUNT(DISTINCT COALESCE(CAST(fecha AS CHAR),'~'))>1,'fecha',NULL),
    IF(COUNT(DISTINCT COALESCE(recibido_d,'~'))>1,'recibido_d',NULL),
    IF(COUNT(DISTINCT COALESCE(nit,'~'))>1,'nit',NULL),
    IF(COUNT(DISTINCT COALESCE(direccion,'~'))>1,'direccion',NULL),
    IF(COUNT(DISTINCT COALESCE(telefono,'~'))>1,'telefono',NULL),
    IF(COUNT(DISTINCT COALESCE(fallecido,'~'))>1,'fallecido',NULL),
    IF(COUNT(DISTINCT COALESCE(forma_pago,'~'))>1,'forma_pago',NULL),
    IF(COUNT(DISTINCT COALESCE(CAST(valor AS CHAR),'~'))>1,'valor',NULL),
    IF(COUNT(DISTINCT COALESCE(funeraria,'~'))>1,'funeraria',NULL),
    IF(COUNT(DISTINCT COALESCE(licencia,'~'))>1,'licencia',NULL),
    IF(COUNT(DISTINCT COALESCE(cementerio,'~'))>1,'cementerio',NULL),
    IF(COUNT(DISTINCT COALESCE(cementeri1,'~'))>1,'cementeri1',NULL),
    IF(COUNT(DISTINCT COALESCE(sector,'~'))>1,'sector',NULL),
    IF(COUNT(DISTINCT COALESCE(pabellon,'~'))>1,'pabellon',NULL),
    IF(COUNT(DISTINCT COALESCE(galeria,'~'))>1,'galeria',NULL),
    IF(COUNT(DISTINCT COALESCE(lugar_inh,'~'))>1,'lugar_inh',NULL),
    IF(COUNT(DISTINCT COALESCE(lugar_no,'~'))>1,'lugar_no',NULL),
    IF(COUNT(DISTINCT COALESCE(fila,'~'))>1,'fila',NULL),
    IF(COUNT(DISTINCT COALESCE(CAST(anulada AS CHAR),'~'))>1,'anulada',NULL),
    IF(COUNT(DISTINCT COALESCE(cedula,'~'))>1,'cedula',NULL),
    IF(COUNT(DISTINCT COALESCE(CAST(fech_anul AS CHAR),'~'))>1,'fech_anul',NULL),
    IF(COUNT(DISTINCT COALESCE(CAST(fec_acc AS CHAR),'~'))>1,'fec_acc',NULL),
    IF(COUNT(DISTINCT COALESCE(CAST(cierre AS CHAR),'~'))>1,'cierre',NULL),
    IF(COUNT(DISTINCT COALESCE(wfalle,'~'))>1,'wfalle',NULL),
    IF(COUNT(DISTINCT COALESCE(rc,'~'))>1,'rc',NULL),
    IF(COUNT(DISTINCT COALESCE(CAST(impreso AS CHAR),'~'))>1,'impreso',NULL)
  ) AS columnas_que_difieren
FROM factura f
WHERE borrado = 0 AND factura IN (
  SELECT factura FROM factura WHERE borrado = 0 AND factura IS NOT NULL
  GROUP BY factura HAVING COUNT(*) > 1)
GROUP BY f.factura
ORDER BY f.factura;



CREATE TABLE factura_bak AS SELECT * FROM factura;

SELECT COUNT(*) AS sobrantes FROM (
  SELECT id, ROW_NUMBER() OVER (
           PARTITION BY factura, fecha, recibido_d, nit, direccion, telefono, fallecido,
                        forma_pago, valor, funeraria, licencia, cementerio, cementeri1,
                        sector, pabellon, galeria, lugar_inh, lugar_no, fila, anulada,
                        cedula, fech_anul, cierre, wfalle, rc, impreso
           ORDER BY id) AS rn
  FROM factura WHERE borrado = 0
) t WHERE rn > 1;


DELETE f
FROM factura f
JOIN (
  SELECT id FROM (
    SELECT id, ROW_NUMBER() OVER (
             PARTITION BY factura, fecha, recibido_d, nit, direccion, telefono, fallecido,
                          forma_pago, valor, funeraria, licencia, cementerio, cementeri1,
                          sector, pabellon, galeria, lugar_inh, lugar_no, fila, anulada,
                          cedula, fech_anul, cierre, wfalle, rc, impreso
             ORDER BY id) AS rn
    FROM factura WHERE borrado = 0
  ) t WHERE rn > 1
) x ON x.id = f.id
WHERE f.id > 0;

DELETE FROM factura
WHERE id = 343230 AND factura = 'F-22613'
  AND fecha IS NULL AND cementerio IS NULL AND forma_pago IS NULL AND valor IS NULL;
  

SELECT COUNT(*) AS activas FROM factura WHERE borrado = 0;

SELECT COUNT(*) AS codigos_repetidos FROM (
  SELECT factura FROM factura WHERE borrado = 0 AND factura IS NOT NULL
  GROUP BY factura HAVING COUNT(*) > 1) x;


SELECT (SELECT COUNT(*) FROM factura_bak WHERE borrado = 0) AS antes,
       (SELECT COUNT(*) FROM factura     WHERE borrado = 0) AS despues;

SELECT b.id, b.factura
FROM factura_bak b
LEFT JOIN factura f ON f.id = b.id
WHERE b.borrado = 0 AND f.id IS NULL
ORDER BY b.factura, b.id;


UPDATE factura
SET funeraria_id = CASE funeraria WHEN '860025393-8' THEN 147 WHEN '900029958-1' THEN 47 END
WHERE id > 0 AND funeraria_id IS NULL AND funeraria IN ('860025393-8', '900029958-1');

UPDATE inhumados
SET funeraria_id = CASE funeraria WHEN '860025393-8' THEN 147 WHEN '900029958-1' THEN 47 END
WHERE id > 0 AND funeraria_id IS NULL AND funeraria IN ('860025393-8', '900029958-1');

UPDATE cremados
SET funeraria_id = CASE funeraria WHEN '860025393-8' THEN 147 WHEN '900029958-1' THEN 47 END
WHERE id > 0 AND funeraria_id IS NULL AND funeraria IN ('860025393-8', '900029958-1');


SELECT 'factura' AS tabla, COUNT(*) AS sin_enlace FROM factura
 WHERE borrado = 0 AND funeraria IS NOT NULL AND funeraria_id IS NULL
UNION ALL SELECT 'inhumados', COUNT(*) FROM inhumados
 WHERE borrado = 0 AND funeraria IS NOT NULL AND funeraria_id IS NULL
UNION ALL SELECT 'cremados', COUNT(*) FROM cremados
 WHERE borrado = 0 AND funeraria IS NOT NULL AND funeraria_id IS NULL;
 
 
 SELECT COUNT(*) AS recuperables
FROM consignaciones c
JOIN (
  SELECT bank, ofi, MIN(id) AS pid
  FROM oficinas
  WHERE borrado = 0
  GROUP BY bank, ofi
  HAVING COUNT(*) = 1
) p ON p.bank = c.banco AND p.ofi = c.oficina
WHERE c.borrado = 0 AND c.oficina_id IS NULL;


SELECT (inhumado_id IS NOT NULL) + (exhumado_id IS NOT NULL) + (cremado_id IS NOT NULL) AS enlaces,
       COUNT(*) AS filas
FROM esqueletos
WHERE borrado = 0 AND factura IS NOT NULL
GROUP BY enlaces
ORDER BY enlaces;


SELECT 'detalle_fact.factura_id' AS enlace, COUNT(*) AS rotas
FROM detalle_fact d LEFT JOIN factura f ON f.id = d.factura_id
WHERE d.factura_id IS NOT NULL AND f.id IS NULL
UNION ALL
SELECT 'inhumados.funeraria_id', COUNT(*)
FROM inhumados i LEFT JOIN funerarias f ON f.id = i.funeraria_id
WHERE i.funeraria_id IS NOT NULL AND f.id IS NULL
UNION ALL
SELECT 'esqueletos.cremado_id', COUNT(*)
FROM esqueletos e LEFT JOIN cremados c ON c.id = e.cremado_id
WHERE e.cremado_id IS NOT NULL AND c.id IS NULL;


SELECT c.tabla, c.activas, e.ea AS activas_esperadas,
       c.borradas, e.eb AS borradas_esperadas,
       IF(c.activas = e.ea AND c.borradas = e.eb, 'OK', 'REVISAR') AS estado
FROM (
  SELECT 'bancos' AS tabla, SUM(borrado=0) AS activas, SUM(borrado=1) AS borradas FROM bancos
  UNION ALL SELECT 'causa_muerte', SUM(borrado=0), SUM(borrado=1) FROM causa_muerte
  UNION ALL SELECT 'cementerios', SUM(borrado=0), SUM(borrado=1) FROM cementerios
  UNION ALL SELECT 'estado_boveda', SUM(borrado=0), SUM(borrado=1) FROM estado_boveda
  UNION ALL SELECT 'forma_pago', SUM(borrado=0), SUM(borrado=1) FROM forma_pago
  UNION ALL SELECT 'galerias', SUM(borrado=0), SUM(borrado=1) FROM galerias
  UNION ALL SELECT 'items', SUM(borrado=0), SUM(borrado=1) FROM items
  UNION ALL SELECT 'lugar_inh', SUM(borrado=0), SUM(borrado=1) FROM lugar_inh
  UNION ALL SELECT 'oficinas', SUM(borrado=0), SUM(borrado=1) FROM oficinas
  UNION ALL SELECT 'parentesco', SUM(borrado=0), SUM(borrado=1) FROM parentesco
  UNION ALL SELECT 'sector', SUM(borrado=0), SUM(borrado=1) FROM sector
  UNION ALL SELECT 'tipo_id', SUM(borrado=0), SUM(borrado=1) FROM tipo_id
  UNION ALL SELECT 'tipo_serv', SUM(borrado=0), SUM(borrado=1) FROM tipo_serv
  UNION ALL SELECT 'tipo_usuario', SUM(borrado=0), SUM(borrado=1) FROM tipo_usuario
  UNION ALL SELECT 'consignaciones', SUM(borrado=0), SUM(borrado=1) FROM consignaciones
  UNION ALL SELECT 'cremados', SUM(borrado=0), SUM(borrado=1) FROM cremados
  UNION ALL SELECT 'detalle_fact', SUM(borrado=0), SUM(borrado=1) FROM detalle_fact
  UNION ALL SELECT 'exhumados', SUM(borrado=0), SUM(borrado=1) FROM exhumados
  UNION ALL SELECT 'factura', SUM(borrado=0), SUM(borrado=1) FROM factura
  UNION ALL SELECT 'funerarias', SUM(borrado=0), SUM(borrado=1) FROM funerarias
  UNION ALL SELECT 'inhumados', SUM(borrado=0), SUM(borrado=1) FROM inhumados
  UNION ALL SELECT 'inventario', SUM(borrado=0), SUM(borrado=1) FROM inventario
  UNION ALL SELECT 'pabellon', SUM(borrado=0), SUM(borrado=1) FROM pabellon
  UNION ALL SELECT 'servicios', SUM(borrado=0), SUM(borrado=1) FROM servicios
  UNION ALL SELECT 'conciliacion', SUM(borrado=0), SUM(borrado=1) FROM conciliacion
  UNION ALL SELECT 'devoluciones', SUM(borrado=0), SUM(borrado=1) FROM devoluciones
  UNION ALL SELECT 'efectivo', SUM(borrado=0), SUM(borrado=1) FROM efectivo
  UNION ALL SELECT 'esqueletos', SUM(borrado=0), SUM(borrado=1) FROM esqueletos
  UNION ALL SELECT 'inhumados_nn', SUM(borrado=0), SUM(borrado=1) FROM inhumados_nn
  UNION ALL SELECT 'prop_lotes', SUM(borrado=0), SUM(borrado=1) FROM prop_lotes
  UNION ALL SELECT 'prop_unidades', SUM(borrado=0), SUM(borrado=1) FROM prop_unidades
  UNION ALL SELECT 'rc', SUM(borrado=0), SUM(borrado=1) FROM rc
) c
JOIN (VALUES
  ROW('bancos', 9, 3), ROW('causa_muerte', 4, 0), ROW('cementerios', 4, 0),
  ROW('estado_boveda', 6, 4), ROW('forma_pago', 7, 0), ROW('galerias', 4, 4),
  ROW('items', 99, 3), ROW('lugar_inh', 7, 2), ROW('oficinas', 815, 2),
  ROW('parentesco', 11, 0), ROW('sector', 2, 1), ROW('tipo_id', 6, 0),
  ROW('tipo_serv', 9, 0), ROW('tipo_usuario', 2, 0),
  ROW('consignaciones', 212000, 24418), ROW('cremados', 299492, 173),
  ROW('detalle_fact', 479324, 27760), ROW('exhumados', 111799, 195),
  ROW('factura', 403652, 21532), ROW('funerarias', 180, 13),
  ROW('inhumados', 94425, 99023), ROW('inventario', 119386, 3691),
  ROW('pabellon', 3161, 1479), ROW('servicios', 829, 292),
  ROW('conciliacion', 481, 0), ROW('devoluciones', 72, 4),
  ROW('efectivo', 3533, 322), ROW('esqueletos', 71116, 0),
  ROW('inhumados_nn', 6052, 117), ROW('prop_lotes', 1233, 132),
  ROW('prop_unidades', 104789, 12890), ROW('rc', 82, 1173)
) AS e(tabla, ea, eb) ON e.tabla = c.tabla
ORDER BY estado DESC, c.tabla;


SELECT table_name, table_rows
FROM information_schema.tables
WHERE table_schema = 'gestion_cementerios' AND table_name LIKE '%\_bak';

SELECT CONCAT('DROP TABLE `', table_name, '`;')
FROM information_schema.tables
WHERE table_schema = 'gestion_cementerios' AND table_name LIKE '%\_bak';

SELECT COUNT(*) FROM information_schema.tables
WHERE table_schema = 'gestion_cementerios' AND table_type = 'BASE TABLE';


SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'gestion_cementerios'
  AND table_type = 'BASE TABLE'
  AND table_name LIKE '%\_bak'
ORDER BY table_name;


SELECT c.tabla, c.activas, e.ea AS activas_esperadas,
       c.borradas, e.eb AS borradas_esperadas,
       IF(c.activas = e.ea AND c.borradas = e.eb, 'OK', 'REVISAR') AS estado
FROM (
  SELECT 'bancos' AS tabla, SUM(borrado=0) AS activas, SUM(borrado=1) AS borradas FROM bancos
  UNION ALL SELECT 'causa_muerte', SUM(borrado=0), SUM(borrado=1) FROM causa_muerte
  UNION ALL SELECT 'cementerios', SUM(borrado=0), SUM(borrado=1) FROM cementerios
  UNION ALL SELECT 'estado_boveda', SUM(borrado=0), SUM(borrado=1) FROM estado_boveda
  UNION ALL SELECT 'forma_pago', SUM(borrado=0), SUM(borrado=1) FROM forma_pago
  UNION ALL SELECT 'galerias', SUM(borrado=0), SUM(borrado=1) FROM galerias
  UNION ALL SELECT 'items', SUM(borrado=0), SUM(borrado=1) FROM items
  UNION ALL SELECT 'lugar_inh', SUM(borrado=0), SUM(borrado=1) FROM lugar_inh
  UNION ALL SELECT 'oficinas', SUM(borrado=0), SUM(borrado=1) FROM oficinas
  UNION ALL SELECT 'parentesco', SUM(borrado=0), SUM(borrado=1) FROM parentesco
  UNION ALL SELECT 'sector', SUM(borrado=0), SUM(borrado=1) FROM sector
  UNION ALL SELECT 'tipo_id', SUM(borrado=0), SUM(borrado=1) FROM tipo_id
  UNION ALL SELECT 'tipo_serv', SUM(borrado=0), SUM(borrado=1) FROM tipo_serv
  UNION ALL SELECT 'tipo_usuario', SUM(borrado=0), SUM(borrado=1) FROM tipo_usuario
  UNION ALL SELECT 'consignaciones', SUM(borrado=0), SUM(borrado=1) FROM consignaciones
  UNION ALL SELECT 'cremados', SUM(borrado=0), SUM(borrado=1) FROM cremados
  UNION ALL SELECT 'detalle_fact', SUM(borrado=0), SUM(borrado=1) FROM detalle_fact
  UNION ALL SELECT 'exhumados', SUM(borrado=0), SUM(borrado=1) FROM exhumados
  UNION ALL SELECT 'factura', SUM(borrado=0), SUM(borrado=1) FROM factura
  UNION ALL SELECT 'funerarias', SUM(borrado=0), SUM(borrado=1) FROM funerarias
  UNION ALL SELECT 'inhumados', SUM(borrado=0), SUM(borrado=1) FROM inhumados
  UNION ALL SELECT 'inventario', SUM(borrado=0), SUM(borrado=1) FROM inventario
  UNION ALL SELECT 'pabellon', SUM(borrado=0), SUM(borrado=1) FROM pabellon
  UNION ALL SELECT 'servicios', SUM(borrado=0), SUM(borrado=1) FROM servicios
  UNION ALL SELECT 'conciliacion', SUM(borrado=0), SUM(borrado=1) FROM conciliacion
  UNION ALL SELECT 'devoluciones', SUM(borrado=0), SUM(borrado=1) FROM devoluciones
  UNION ALL SELECT 'efectivo', SUM(borrado=0), SUM(borrado=1) FROM efectivo
  UNION ALL SELECT 'esqueletos', SUM(borrado=0), SUM(borrado=1) FROM esqueletos
  UNION ALL SELECT 'inhumados_nn', SUM(borrado=0), SUM(borrado=1) FROM inhumados_nn
  UNION ALL SELECT 'prop_lotes', SUM(borrado=0), SUM(borrado=1) FROM prop_lotes
  UNION ALL SELECT 'prop_unidades', SUM(borrado=0), SUM(borrado=1) FROM prop_unidades
  UNION ALL SELECT 'rc', SUM(borrado=0), SUM(borrado=1) FROM rc
) c
JOIN (
  SELECT 'bancos' AS tabla, 9 AS ea, 3 AS eb
  UNION ALL SELECT 'causa_muerte', 4, 0
  UNION ALL SELECT 'cementerios', 4, 0
  UNION ALL SELECT 'estado_boveda', 6, 4
  UNION ALL SELECT 'forma_pago', 7, 0
  UNION ALL SELECT 'galerias', 4, 4
  UNION ALL SELECT 'items', 99, 3
  UNION ALL SELECT 'lugar_inh', 7, 2
  UNION ALL SELECT 'oficinas', 815, 2
  UNION ALL SELECT 'parentesco', 11, 0
  UNION ALL SELECT 'sector', 2, 1
  UNION ALL SELECT 'tipo_id', 6, 0
  UNION ALL SELECT 'tipo_serv', 9, 0
  UNION ALL SELECT 'tipo_usuario', 2, 0
  UNION ALL SELECT 'consignaciones', 212000, 24418
  UNION ALL SELECT 'cremados', 299492, 173
  UNION ALL SELECT 'detalle_fact', 479324, 27760
  UNION ALL SELECT 'exhumados', 111799, 195
  UNION ALL SELECT 'factura', 403652, 21532
  UNION ALL SELECT 'funerarias', 180, 13
  UNION ALL SELECT 'inhumados', 94425, 99023
  UNION ALL SELECT 'inventario', 119386, 3691
  UNION ALL SELECT 'pabellon', 3161, 1479
  UNION ALL SELECT 'servicios', 829, 292
  UNION ALL SELECT 'conciliacion', 481, 0
  UNION ALL SELECT 'devoluciones', 72, 4
  UNION ALL SELECT 'efectivo', 3533, 322
  UNION ALL SELECT 'esqueletos', 71116, 0
  UNION ALL SELECT 'inhumados_nn', 6052, 117
  UNION ALL SELECT 'prop_lotes', 1233, 132
  UNION ALL SELECT 'prop_unidades', 104789, 12890
  UNION ALL SELECT 'rc', 82, 1173
) e ON e.tabla = c.tabla
ORDER BY estado DESC, c.tabla;

SELECT table_name, table_rows
FROM information_schema.tables
WHERE table_schema = 'gestion_cementerios'
ORDER BY table_name;


SELECT table_name,
       GROUP_CONCAT(column_name ORDER BY ordinal_position SEPARATOR ', ') AS columnas
FROM information_schema.columns
WHERE table_schema = 'gestion_cementerios'
  AND table_name IN (
    'v_inhumados_activos', 'v_cremados_activos', 'v_exhumados_activos',
    'v_factura_activos', 'v_detalle_fact_activos', 'v_prop_unidades_activos',
    'v_cementerios_activos', 'v_oficinas_activos', 'v_consignaciones_activos'
  )
GROUP BY table_name;


SELECT COUNT(*) AS total,
       SUM(prop_nit IS NOT NULL AND prop_nit <> '') AS con_nit,
       COUNT(DISTINCT prop_nit) AS nits_distintos,
       COUNT(DISTINCT prop_lote_id) AS lotes_distintos
FROM v_prop_unidades_activos;


SELECT 'inhumados' AS tabla, MIN(YEAR(fecha_inh)) AS desde, MAX(YEAR(fecha_inh)) AS hasta FROM v_inhumados_activos
UNION ALL
SELECT 'cremados', MIN(YEAR(fecha_cre)), MAX(YEAR(fecha_cre)) FROM v_cremados_activos
UNION ALL
SELECT 'exhumados', MIN(YEAR(fecha_exh)), MAX(YEAR(fecha_exh)) FROM v_exhumados_activos
UNION ALL
SELECT 'facturas', MIN(YEAR(fecha)), MAX(YEAR(fecha)) FROM v_factura_activos;


SELECT FLOOR(YEAR(fecha_inh) / 10) * 10 AS decada, COUNT(*) AS n
FROM v_inhumados_activos
WHERE fecha_inh IS NOT NULL
GROUP BY decada
ORDER BY decada;


SELECT anulada, COUNT(*) AS n, SUM(valor) AS total
FROM v_factura_activos
GROUP BY anulada;


SELECT t.cementerio, c.nombre, COUNT(*) AS n
FROM (
    SELECT cementerio FROM v_inhumados_activos
    UNION ALL
    SELECT cementerio FROM v_cremados_activos
) t
LEFT JOIN v_cementerios_activos c ON c.cementerio = t.cementerio
GROUP BY t.cementerio, c.nombre
ORDER BY n DESC;



SELECT estado, COUNT(*) AS n
FROM v_prop_unidades_activos
GROUP BY estado
ORDER BY n DESC;

SELECT * FROM v_estado_boveda_activos;


SELECT * FROM v_funerarias_activos LIMIT 5;
SELECT funeraria, COUNT(*) AS n
FROM v_factura_activos
GROUP BY funeraria
ORDER BY n DESC
LIMIT 5;

SELECT column_name
FROM information_schema.columns
WHERE table_schema = 'gestion_cementerios'
  AND table_name = 'v_factura_activos'
  AND column_name LIKE '%fun%';
  
  
CREATE TABLE IF NOT EXISTS log_cambios (
    id INT AUTO_INCREMENT PRIMARY KEY,
    fecha DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    usuario VARCHAR(50) NOT NULL,
    accion ENUM('crear','modificar','eliminar','restaurar') NOT NULL,
    tabla VARCHAR(64) NOT NULL,
    registro_id INT NULL,
    detalle TEXT NULL,
    ip VARCHAR(45) NULL,
    INDEX (tabla, registro_id),
    INDEX (fecha)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

SHOW GRANTS FOR CURRENT_USER();

SELECT c.table_name, c.column_name, c.column_default, c.extra
FROM information_schema.columns c
JOIN information_schema.tables t
  ON t.table_schema = c.table_schema AND t.table_name = c.table_name
WHERE c.table_schema = 'gestion_cementerios'
  AND t.table_type = 'BASE TABLE'
  AND RIGHT(c.table_name, 4) <> '_bak'
  AND c.column_name IN ('id', 'borrado')
ORDER BY c.table_name, c.column_name;

SELECT table_name, column_name, data_type, column_key, extra
FROM information_schema.columns
WHERE table_schema = 'gestion_cementerios'
  AND table_name IN ('funerarias', 'prop_lotes', 'inhumados')
ORDER BY table_name, ordinal_position;
  
  
 SELECT 'inhumados.nit_deudo' AS columna, COUNT(*) AS total,
       SUM(nit_deudo IS NOT NULL AND nit_deudo <> '') AS llenos,
       COUNT(DISTINCT nit_deudo) AS distintos
FROM v_inhumados_activos
UNION ALL
SELECT 'inhumados.cedula', COUNT(*),
       SUM(cedula IS NOT NULL AND cedula <> ''), COUNT(DISTINCT cedula)
FROM v_inhumados_activos
UNION ALL
SELECT 'cremados.nit_deudo', COUNT(*),
       SUM(nit_deudo IS NOT NULL AND nit_deudo <> ''), COUNT(DISTINCT nit_deudo)
FROM v_cremados_activos
UNION ALL
SELECT 'cremados.cedula', COUNT(*),
       SUM(cedula IS NOT NULL AND cedula <> ''), COUNT(DISTINCT cedula)
FROM v_cremados_activos
UNION ALL
SELECT 'exhumados.nit_deudo', COUNT(*),
       SUM(nit_deudo IS NOT NULL AND nit_deudo <> ''), COUNT(DISTINCT nit_deudo)
FROM v_exhumados_activos
UNION ALL
SELECT 'prop_unidades.prop_nit', COUNT(*),
       SUM(prop_nit IS NOT NULL AND prop_nit <> ''), COUNT(DISTINCT prop_nit)
FROM v_prop_unidades_activos;


CREATE TABLE IF NOT EXISTS log_consultas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    fecha DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ip VARCHAR(45) NULL,
    doc_hash CHAR(64) NOT NULL,
    resultado ENUM('ok','fallo') NOT NULL,
    n_registros INT NOT NULL DEFAULT 0,
    INDEX (fecha),
    INDEX (ip, fecha)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;