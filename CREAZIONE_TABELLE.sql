-- creo il database UninaTaskBoard
CREATE DATABASE UninaTaskBoard;
\c UninaTaskBoard;

-- ============================================================================
-- DEFINIZIONE TIPI ENUM
-- ============================================================================
CREATE TYPE ruolo_membro AS ENUM ('creatore', 'membro');
CREATE TYPE stato_attivita AS ENUM ('non_iniziata', 'in_corso', 'completata');
CREATE TYPE tipo_attivita AS ENUM ('documentazione', 'sviluppo');
CREATE TYPE livello_priorita AS ENUM ('bassa', 'media', 'alta', 'urgente');
CREATE TYPE tipo_notifica AS ENUM ('scadenza_imminente', 'cambiamento_stato');

-- 1. TABELLA: utente
-- ============================================================================
-- SCOPO: Memorizza tutti gli studenti registrati alla piattaforma
-- ============================================================================

CREATE TABLE utente (
    id_utente SERIAL PRIMARY KEY,
    matricola VARCHAR(10) UNIQUE NOT NULL,
    nome VARCHAR(50) NOT NULL,
    cognome VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    data_registrazione DATE NOT NULL DEFAULT CURRENT_DATE,

    -- Vincolo: formato email istituzionale
    CONSTRAINT chk_email_format CHECK (email ~* '^[A-Za-z0-9._%+-]+@studenti\.unina\.it$')
);



-- ============================================================================
-- 2. TABELLA: progetto
-- ============================================================================
-- SCOPO: Rappresenta un progetto collaborativo creato da uno studente
-- ============================================================================

CREATE TABLE progetto (
    id_progetto SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    descrizione TEXT,
    data_creazione DATE NOT NULL DEFAULT CURRENT_DATE,
    id_creatore INTEGER NOT NULL,

    -- Vincolo: il creatore deve esistere nella tabella utente
    CONSTRAINT fk_progetto_creatore FOREIGN KEY (id_creatore)
        REFERENCES utente(id_utente) ON DELETE RESTRICT
);



-- ============================================================================
-- 3. TABELLA: membro_progetto
-- ============================================================================
-- SCOPO: Tabella ponte N:M che associa utenti a progetti con specifici ruoli
-- ============================================================================

CREATE TABLE membro_progetto (
    id_utente INTEGER NOT NULL,
    id_progetto INTEGER NOT NULL,
    ruolo ruolo_membro NOT NULL,
    data_ingresso DATE NOT NULL DEFAULT CURRENT_DATE,

    -- Chiave primaria composta: un utente può essere membro una sola volta di ogni progetto
    CONSTRAINT pk_membro_progetto PRIMARY KEY (id_utente, id_progetto),

    -- Foreign Keys
    CONSTRAINT fk_membro_progetto_utente FOREIGN KEY (id_utente)
        REFERENCES utente(id_utente) ON DELETE CASCADE,

    CONSTRAINT fk_membro_progetto_progetto FOREIGN KEY (id_progetto)
        REFERENCES progetto(id_progetto) ON DELETE CASCADE
);



-- ============================================================================
-- 4. TABELLA: attivita
-- ============================================================================
-- SCOPO: Entità centrale che rappresenta ogni singola attività di un progetto
-- ============================================================================

CREATE TABLE attivita (
    id_attivita SERIAL PRIMARY KEY,
    id_progetto INTEGER NOT NULL,
    titolo VARCHAR(150) NOT NULL,
    descrizione TEXT,
    data_creazione DATE NOT NULL DEFAULT CURRENT_DATE,
    data_scadenza DATE,
    stato stato_attivita NOT NULL DEFAULT 'non_iniziata',
    tipo tipo_attivita NOT NULL,

    -- Foreign Key: ogni attività appartiene a un progetto
    CONSTRAINT fk_attivita_progetto FOREIGN KEY (id_progetto)
        REFERENCES progetto(id_progetto) ON DELETE CASCADE,

    -- Vincolo: scadenza deve essere successiva alla creazione
    CONSTRAINT chk_scadenza CHECK (data_scadenza IS NULL OR data_scadenza > data_creazione)
);



-- ============================================================================
-- 5. TABELLA: documentazione
-- ============================================================================
-- SCOPO: Specializzazione di attivita per contenuti documentali (PDF, DOCX, etc)
-- ============================================================================

CREATE TABLE documentazione (
    id_attivita INTEGER PRIMARY KEY,
    formato VARCHAR(30),

    -- Foreign Key all'attività padre (relazione 1:1)
    CONSTRAINT fk_documentazione_attivita FOREIGN KEY (id_attivita)
        REFERENCES attivita(id_attivita) ON DELETE CASCADE
);



-- ============================================================================
-- 6. TABELLA: sviluppo
-- ============================================================================
-- SCOPO: Specializzazione di attivita per sviluppo software (codice sorgente)
-- ============================================================================

CREATE TABLE sviluppo (
    id_attivita INTEGER PRIMARY KEY,
    linguaggio_principale VARCHAR(50),
    repository_url VARCHAR(255),

    -- Foreign Key all'attività padre (relazione 1:1)
    CONSTRAINT fk_sviluppo_attivita FOREIGN KEY (id_attivita)
        REFERENCES attivita(id_attivita) ON DELETE CASCADE
);



-- ============================================================================
-- 7. TABELLA: assegnazione
-- ============================================================================
-- SCOPO: Tabella ponte N:M che assegna attività a membri del progetto
-- ============================================================================

CREATE TABLE assegnazione (
    id_attivita INTEGER NOT NULL,
    id_utente INTEGER NOT NULL,
    data_assegnazione DATE NOT NULL DEFAULT CURRENT_DATE,

    -- Chiave primaria composta: un utente non può essere assegnato più volte alla stessa attività
    CONSTRAINT pk_assegnazione PRIMARY KEY (id_attivita, id_utente),

    -- Foreign Keys
    CONSTRAINT fk_assegnazione_attivita FOREIGN KEY (id_attivita)
        REFERENCES attivita(id_attivita) ON DELETE CASCADE,

    CONSTRAINT fk_assegnazione_utente FOREIGN KEY (id_utente)
        REFERENCES utente(id_utente) ON DELETE CASCADE
);



-- ============================================================================
-- 8. TABELLA: file_codice
-- ============================================================================
-- SCOPO: Memorizza i file sorgente associati alle attività di sviluppo
-- ============================================================================

CREATE TABLE file_codice (
    id_file SERIAL PRIMARY KEY,
    id_attivita INTEGER NOT NULL,
    nome_file VARCHAR(100) NOT NULL,
    percorso VARCHAR(255),
    data_creazione DATE NOT NULL DEFAULT CURRENT_DATE,

    -- Foreign Key verso sviluppo (garantisce che l'attività sia di sviluppo)
    CONSTRAINT fk_file_codice_attivita FOREIGN KEY (id_attivita)
        REFERENCES sviluppo(id_attivita) ON DELETE CASCADE
);



-- ============================================================================
-- 9. TABELLA: revisione
-- ============================================================================
-- SCOPO: Traccia lo storico delle modifiche apportate a ogni file di codice
-- ============================================================================

CREATE TABLE revisione (
    id_revisione SERIAL PRIMARY KEY,
    id_file INTEGER NOT NULL,
    id_autore INTEGER NOT NULL,
    data_modifica TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    numero_versione INTEGER NOT NULL,
    nota_descrittiva TEXT NOT NULL,

    -- Foreign Keys
    CONSTRAINT fk_revisione_file FOREIGN KEY (id_file)
        REFERENCES file_codice(id_file) ON DELETE CASCADE,

    CONSTRAINT fk_revisione_autore FOREIGN KEY (id_autore)
        REFERENCES utente(id_utente) ON DELETE RESTRICT
);



-- ============================================================================
-- 10. TABELLA: commento
-- ============================================================================
-- SCOPO: Permette ai membri di un progetto di lasciare commenti sulle attività
-- ============================================================================

CREATE TABLE commento (
    id_commento SERIAL PRIMARY KEY,
    id_attivita INTEGER NOT NULL,
    id_utente INTEGER NOT NULL,
    testo TEXT NOT NULL,
    timestamp_commento TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Foreign Keys
    CONSTRAINT fk_commento_attivita FOREIGN KEY (id_attivita)
        REFERENCES attivita(id_attivita) ON DELETE CASCADE,

    CONSTRAINT fk_commento_utente FOREIGN KEY (id_utente)
        REFERENCES utente(id_utente) ON DELETE CASCADE
);



-- ============================================================================
-- 11. TABELLA: priorita (EXTRA - solo per progetti con >=3 membri)
-- ============================================================================
-- SCOPO: Permette di assegnare priorità alle attività (solo progetti grandi)
-- ============================================================================

CREATE TABLE priorita (
    id_priorita SERIAL PRIMARY KEY,
    id_attivita INTEGER NOT NULL,
    livello livello_priorita NOT NULL,
    data_assegnazione DATE NOT NULL DEFAULT CURRENT_DATE,

    -- Foreign Key
    CONSTRAINT fk_priorita_attivita FOREIGN KEY (id_attivita)
        REFERENCES attivita(id_attivita) ON DELETE CASCADE,

    -- Unica priorità per attività (relazione 1:0..1)
    CONSTRAINT unq_priorita_attivita UNIQUE (id_attivita)
);



-- ============================================================================
-- 12. TABELLA: notifica (EXTRA - solo per progetti con >=3 membri)
-- ============================================================================
-- SCOPO: Invia notifiche ai membri per scadenze imminenti o cambi di stato
-- ============================================================================

CREATE TABLE notifica (
    id_notifica SERIAL PRIMARY KEY,
    id_attivita INTEGER NOT NULL,
    id_utente INTEGER NOT NULL,
    tipo tipo_notifica NOT NULL,
    letta BOOLEAN NOT NULL DEFAULT FALSE,
    data_creazione TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Foreign Keys
    CONSTRAINT fk_notifica_attivita FOREIGN KEY (id_attivita)
        REFERENCES attivita(id_attivita) ON DELETE CASCADE,

    CONSTRAINT fk_notifica_utente FOREIGN KEY (id_utente)
        REFERENCES utente(id_utente) ON DELETE CASCADE
);



-- ============================================================================
-- TRIGGER: Implementazione vincoli logici complessi
-- ============================================================================

-- ----------------------------------------------------------------------------
-- TRIGGER 1: Verifica che l'utente assegnato sia membro del progetto
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION check_assegnazione_membro()
RETURNS TRIGGER AS $$
DECLARE
    v_is_membro INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_is_membro
    FROM membro_progetto
    WHERE id_utente = NEW.id_utente
      AND id_progetto = (SELECT id_progetto FROM attivita WHERE id_attivita = NEW.id_attivita);

    IF v_is_membro = 0 THEN
        RAISE EXCEPTION 'L''utente % non è membro del progetto e non può essere assegnato', NEW.id_utente;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_assegnazione_membro
    BEFORE INSERT ON assegnazione
    FOR EACH ROW
    EXECUTE FUNCTION check_assegnazione_membro();


-- ----------------------------------------------------------------------------
-- TRIGGER 2: Verifica che l'utente che commenta sia membro del progetto
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION check_commento_membro()
RETURNS TRIGGER AS $$
DECLARE
    v_is_membro INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_is_membro
    FROM membro_progetto
    WHERE id_utente = NEW.id_utente
      AND id_progetto = (SELECT id_progetto FROM attivita WHERE id_attivita = NEW.id_attivita);

    IF v_is_membro = 0 THEN
        RAISE EXCEPTION 'L''utente % non è membro del progetto e non può commentare', NEW.id_utente;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_commento_membro
    BEFORE INSERT ON commento
    FOR EACH ROW
    EXECUTE FUNCTION check_commento_membro();


-- ----------------------------------------------------------------------------
-- TRIGGER 3: Verifica che la scadenza sia successiva alla creazione
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION check_scadenza_attivita()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.data_scadenza IS NOT NULL AND NEW.data_scadenza <= NEW.data_creazione THEN
        RAISE EXCEPTION 'La data di scadenza deve essere successiva alla data di creazione';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_scadenza_attivita
    BEFORE INSERT OR UPDATE ON attivita
    FOR EACH ROW
    EXECUTE FUNCTION check_scadenza_attivita();


-- ----------------------------------------------------------------------------
-- TRIGGER 4: Auto-increment del numero di versione per le revisioni
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION autoincrement_versione()
RETURNS TRIGGER AS $$
DECLARE
    v_max_versione INTEGER;
BEGIN
    SELECT COALESCE(MAX(numero_versione), 0) INTO v_max_versione
    FROM revisione
    WHERE id_file = NEW.id_file;

    NEW.numero_versione := v_max_versione + 1;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_autoincrement_versione
    BEFORE INSERT ON revisione
    FOR EACH ROW
    EXECUTE FUNCTION autoincrement_versione();


-- ----------------------------------------------------------------------------
-- TRIGGER 5: Verifica che il file sia associato solo ad attività di sviluppo
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION check_tipo_file()
RETURNS TRIGGER AS $$
DECLARE
    v_tipo_attivita tipo_attivita;
BEGIN
    SELECT tipo INTO v_tipo_attivita
    FROM attivita
    WHERE id_attivita = NEW.id_attivita;

    IF v_tipo_attivita != 'sviluppo' THEN
        RAISE EXCEPTION 'I file di codice possono essere associati solo ad attività di sviluppo';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM sviluppo WHERE id_attivita = NEW.id_attivita) THEN
        RAISE EXCEPTION 'L''attività % non è registrata come attività di sviluppo', NEW.id_attivita;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_tipo_file
    BEFORE INSERT ON file_codice
    FOR EACH ROW
    EXECUTE FUNCTION check_tipo_file();


-- ----------------------------------------------------------------------------
-- TRIGGER 6: Verifica che il progetto abbia almeno 3 membri per assegnare priorità
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION check_priorita_progetto_3_membri()
RETURNS TRIGGER AS $$
DECLARE
    v_numero_membri INTEGER;
    v_id_progetto INTEGER;
BEGIN
    SELECT id_progetto INTO v_id_progetto
    FROM attivita
    WHERE id_attivita = NEW.id_attivita;

    SELECT COUNT(*) INTO v_numero_membri
    FROM membro_progetto
    WHERE id_progetto = v_id_progetto;

    IF v_numero_membri < 3 THEN
        RAISE EXCEPTION 'Le priorità sono disponibili solo per progetti con almeno 3 membri (attuali: %)', v_numero_membri;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_priorita_3_membri
    BEFORE INSERT ON priorita
    FOR EACH ROW
    EXECUTE FUNCTION check_priorita_progetto_3_membri();


-- ----------------------------------------------------------------------------
-- TRIGGER 7: Verifica che il progetto abbia almeno 3 membri per creare notifiche
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION check_notifica_progetto_3_membri()
RETURNS TRIGGER AS $$
DECLARE
    v_numero_membri INTEGER;
    v_id_progetto INTEGER;
BEGIN
    SELECT id_progetto INTO v_id_progetto
    FROM attivita
    WHERE id_attivita = NEW.id_attivita;

    SELECT COUNT(*) INTO v_numero_membri
    FROM membro_progetto
    WHERE id_progetto = v_id_progetto;

    IF v_numero_membri < 3 THEN
        RAISE EXCEPTION 'Le notifiche sono disponibili solo per progetti con almeno 3 membri (attuali: %)', v_numero_membri;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_notifica_3_membri
    BEFORE INSERT ON notifica
    FOR EACH ROW
    EXECUTE FUNCTION check_notifica_progetto_3_membri();


-- ============================================================================
-- AUTOMAZIONE: NUOVI TRIGGER
-- ============================================================================

-- ----------------------------------------------------------------------------
-- TRIGGER 8: Aggiunta automatica del creatore come membro del progetto
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION auto_membro_creatore()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO membro_progetto (id_utente, id_progetto, ruolo, data_ingresso)
    VALUES (NEW.id_creatore, NEW.id_progetto, 'creatore', NEW.data_creazione);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_auto_membro_creatore
    AFTER INSERT ON progetto
    FOR EACH ROW
    EXECUTE FUNCTION auto_membro_creatore();


-- ----------------------------------------------------------------------------
-- TRIGGER 9: Generazione automatica notifiche al cambio stato
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION genera_notifica_stato()
RETURNS TRIGGER AS $$
DECLARE
    v_membro RECORD;
    v_numero_membri INTEGER;
BEGIN
    -- Verifica che il progetto abbia almeno 3 membri
    SELECT COUNT(*) INTO v_numero_membri
    FROM membro_progetto
    WHERE id_progetto = NEW.id_progetto;

    IF v_numero_membri >= 3 THEN
        -- Notifica tutti i membri tranne (opzionalmente) chi ha fatto la modifica?
        -- Per semplicità notifichiamo tutti
        FOR v_membro IN SELECT id_utente FROM membro_progetto WHERE id_progetto = NEW.id_progetto LOOP
            INSERT INTO notifica (id_attivita, id_utente, tipo)
            VALUES (NEW.id_attivita, v_membro.id_utente, 'cambiamento_stato');
        END LOOP;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_genera_notifica_stato
    AFTER UPDATE OF stato ON attivita
    FOR EACH ROW
    WHEN (OLD.stato IS DISTINCT FROM NEW.stato)
    EXECUTE FUNCTION genera_notifica_stato();


-- ============================================================================
-- PROCEDURE E FUNZIONI
-- ============================================================================

-- ----------------------------------------------------------------------------
-- PROCEDURE: aggiungi_membro_progetto
-- ----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE aggiungi_membro_progetto(
    p_id_utente INTEGER,
    p_id_progetto INTEGER,
    p_ruolo ruolo_membro DEFAULT 'membro'
)
AS $$
BEGIN
    INSERT INTO membro_progetto (id_utente, id_progetto, ruolo)
    VALUES (p_id_utente, p_id_progetto, p_ruolo)
    ON CONFLICT (id_utente, id_progetto) DO NOTHING;
END;
$$ LANGUAGE plpgsql;


-- ----------------------------------------------------------------------------
-- PROCEDURE: cambia_stato_attivita
-- ----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE cambia_stato_attivita(
    p_id_attivita INTEGER,
    p_nuovo_stato stato_attivita
)
AS $$
BEGIN
    UPDATE attivita
    SET stato = p_nuovo_stato
    WHERE id_attivita = p_id_attivita;
END;
$$ LANGUAGE plpgsql;


-- ----------------------------------------------------------------------------
-- FUNCTION: get_report_progetto
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION get_report_progetto(p_id_progetto INTEGER)
RETURNS TABLE (
    totale_attivita BIGINT,
    completate BIGINT,
    in_corso BIGINT,
    non_iniziate BIGINT,
    numero_membri BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        COUNT(a.id_attivita) as totale,
        COUNT(a.id_attivita) FILTER (WHERE a.stato = 'completata') as comp,
        COUNT(a.id_attivita) FILTER (WHERE a.stato = 'in_corso') as inc,
        COUNT(a.id_attivita) FILTER (WHERE a.stato = 'non_iniziata') as nonin,
        (SELECT COUNT(*) FROM membro_progetto WHERE id_progetto = p_id_progetto) as membri
    FROM attivita a
    WHERE a.id_progetto = p_id_progetto;
END;
$$ LANGUAGE plpgsql;


-- ============================================================================
-- VISTE
-- ============================================================================

-- ----------------------------------------------------------------------------
-- VISTA: vista_attivita_dettagliata
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW vista_attivita_dettagliata AS
SELECT
    a.*,
    d.formato,
    s.linguaggio_principale,
    s.repository_url,
    p.nome as nome_progetto
FROM attivita a
LEFT JOIN documentazione d ON a.id_attivita = d.id_attivita
LEFT JOIN sviluppo s ON a.id_attivita = s.id_attivita
JOIN progetto p ON a.id_progetto = p.id_progetto;


-- ----------------------------------------------------------------------------
-- VISTA: vista_membri_progetto
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW vista_membri_progetto AS
SELECT
    mp.id_progetto,
    p.nome as nome_progetto,
    u.id_utente,
    u.nome,
    u.cognome,
    u.email,
    mp.ruolo,
    mp.data_ingresso
FROM membro_progetto mp
JOIN utente u ON mp.id_utente = u.id_utente
JOIN progetto p ON mp.id_progetto = p.id_progetto;


-- ============================================================================
-- INDICI PER PRESTAZIONI
-- ============================================================================
CREATE INDEX idx_attivita_progetto ON attivita(id_progetto);
CREATE INDEX idx_membro_progetto ON membro_progetto(id_progetto);
CREATE INDEX idx_assegnazione_utente ON assegnazione(id_utente);
CREATE INDEX idx_file_attivita ON file_codice(id_attivita);
CREATE INDEX idx_revisione_file ON revisione(id_file);
CREATE INDEX idx_commento_attivita ON commento(id_attivita);


-- ============================================================================
-- RIEPILOGO FINALE
-- ============================================================================
-- Database: UninaTaskBoard (Migliorato)
-- Tipi ENUM implementati per maggiore robustezza.
-- Trigger aggiuntivi per automazione (creatore automatico, notifiche stato).
-- Procedure e Funzioni per business logic centralizzata.
-- Viste per semplificare l'interrogazione dei dati.
-- Indici ottimizzati per le performance.
-- ============================================================================
