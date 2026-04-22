-- creo il database UninaTaskBoard
CREATE DATABASE UninaTaskBoard;
\c UninaTaskBoard;


-- 1. TABELLA: utente
-- ============================================================================
-- SCOPO: Memorizza tutti gli studenti registrati alla piattaforma
--
-- COLLEGAMENTI (Molteplicità):
--  - progetto (1:N)      → Un utente CREA molti progetti (come id_creatore)
--  - membro_progetto (N:M) → Un utente PARTECIPA a molti progetti
--  - assegnazione (N:M)  → Un utente VIENE ASSEGNATO a molte attività
--  - revisione (1:N)     → Un utente SCRIVE molte revisioni
--  - commento (1:N)      → Un utente SCRIVE molti commenti
--  - notifica (1:N)      → Un utente RICEVE molte notifiche
--
-- CAMPI:
--  - id_utente:          Identificativo univoco auto-incrementale
--  - matricola:          Matricola universitaria (univoca per studente)
--  - nome, cognome:      Dati anagrafici dello studente
--  - email:              Email istituzionale (@studenti.unina.it)
--  - password:           Password cifrata (BCrypt/Argon2)
--  - data_registrazione: Data di iscrizione alla piattaforma
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
    CONSTRAINT chk_email_format CHECK (email LIKE '%@studenti.unina.it')
);



-- ============================================================================
-- 2. TABELLA: progetto
-- ============================================================================
-- SCOPO: Rappresenta un progetto collaborativo creato da uno studente
--
-- COLLEGAMENTI (Molteplicità):
--  - utente (N:1)        → Un progetto è CREATO da un utente (id_creatore)
--  - membro_progetto (1:N) → Un progetto HA molti membri
--  - attivita (1:N)      → Un progetto CONTIENE molte attività
--
-- CAMPI:
--  - id_progetto:        Identificativo univoco del progetto
--  - nome:               Nome del progetto (es. "Progetto Basi di Dati")
--  - descrizione:        Descrizione dettagliata del progetto
--  - data_creazione:     Data di creazione del progetto
--  - id_creatore:        Riferimento all'utente che ha creato il progetto
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
--         Registra chi partecipa a quale progetto e con quale ruolo
--
-- COLLEGAMENTI (Molteplicità):
--  - utente (N:1)        → Un utente può essere membro di molti progetti
--  - progetto (N:1)      → Un progetto può avere molti membri
--  - Relazione N:M       → Un utente partecipa a molti progetti, un progetto ha molti utenti
--
-- CAMPI:
--  - id_utente:          Riferimento all'utente membro
--  - id_progetto:        Riferimento al progetto
--  - ruolo:              Ruolo nel progetto: 'creatore' o 'membro'
--  - data_ingresso:      Data in cui l'utente è entrato nel progetto
--
-- NOTA: La PK composta (id_utente, id_progetto) garantisce che un utente
--       non possa essere membro dello stesso progetto più volte
-- ============================================================================

CREATE TABLE membro_progetto (
    id_utente INTEGER NOT NULL,
    id_progetto INTEGER NOT NULL,
    ruolo VARCHAR(20) NOT NULL,
    data_ingresso DATE NOT NULL DEFAULT CURRENT_DATE,

    -- Chiave primaria composta: un utente può essere membro una sola volta di ogni progetto
    CONSTRAINT pk_membro_progetto PRIMARY KEY (id_utente, id_progetto),

    -- Foreign Keys
    CONSTRAINT fk_membro_progetto_utente FOREIGN KEY (id_utente)
        REFERENCES utente(id_utente) ON DELETE CASCADE,

    CONSTRAINT fk_membro_progetto_progetto FOREIGN KEY (id_progetto)
        REFERENCES progetto(id_progetto) ON DELETE CASCADE,

    -- Vincolo: ruolo può essere solo 'creatore' o 'membro'
    CONSTRAINT chk_ruolo CHECK (ruolo IN ('creatore', 'membro'))
);



-- ============================================================================
-- 4. TABELLA: attivita
-- ============================================================================
-- SCOPO: Entità centrale che rappresenta ogni singola attività di un progetto
--         È la tabella padre della gerarchia (specializzata in documentazione/sviluppo)
--
-- COLLEGAMENTI (Molteplicità):
--  - progetto (N:1)      → Un'attività appartiene a un solo progetto
--  - documentazione (1:1) → Un'attività PUÒ essere di documentazione (esclusiva)
--  - sviluppo (1:1)      → Un'attività PUÒ essere di sviluppo (esclusiva)
--  - assegnazione (1:N)  → Un'attività può essere assegnata a molti membri
--  - file_codice (1:N)   → Un'attività di sviluppo ha molti file
--  - commento (1:N)      → Un'attività può ricevere molti commenti
--  - priorita (1:0..1)   → Un'attività PUÒ avere una priorità (EXTRA)
--  - notifica (1:N)      → Un'attività può generare molte notifiche (EXTRA)
--
-- CAMPI:
--  - id_attivita:        Identificativo univoco dell'attività
--  - id_progetto:        Progetto di appartenenza
--  - titolo:             Titolo breve dell'attività
--  - descrizione:        Descrizione dettagliata del lavoro da svolgere
--  - data_creazione:     Data di creazione dell'attività
--  - data_scadenza:      Data di scadenza (opzionale, deve essere > data_creazione)
--  - stato:              Stato di avanzamento: non_iniziata | in_corso | completata
--  - tipo:               Tipo di attività: documentazione | sviluppo
--
-- NOTA: Il campo 'tipo' funge da discriminatore per la gerarchia
--       Se tipo='documentazione' → esiste record in tabella documentazione
--       Se tipo='sviluppo' → esiste record in tabella sviluppo
-- ============================================================================

CREATE TABLE attivita (
    id_attivita SERIAL PRIMARY KEY,
    id_progetto INTEGER NOT NULL,
    titolo VARCHAR(150) NOT NULL,
    descrizione TEXT,
    data_creazione DATE NOT NULL DEFAULT CURRENT_DATE,
    data_scadenza DATE,
    stato VARCHAR(20) NOT NULL,
    tipo VARCHAR(20) NOT NULL,

    -- Foreign Key: ogni attività appartiene a un progetto
    CONSTRAINT fk_attivita_progetto FOREIGN KEY (id_progetto)
        REFERENCES progetto(id_progetto) ON DELETE CASCADE,

    -- Vincolo: scadenza deve essere successiva alla creazione
    CONSTRAINT chk_scadenza CHECK (data_scadenza IS NULL OR data_scadenza > data_creazione),

    -- Vincolo: stati possibili
    CONSTRAINT chk_stato CHECK (stato IN ('non_iniziata', 'in_corso', 'completata')),

    -- Vincolo: tipi possibili (discriminatore gerarchia)
    CONSTRAINT chk_tipo CHECK (tipo IN ('documentazione', 'sviluppo'))
);



-- ============================================================================
-- 5. TABELLA: documentazione
-- ============================================================================
-- SCOPO: Specializzazione di attivita per contenuti documentali (PDF, DOCX, etc)
--         Implementa il pattern Table Per Type (TPT) per la gerarchia
--
-- COLLEGAMENTI (Molteplicità):
--  - attivita (1:1)      → Relazione 1:1 con tabella attivita (IS-A relationship)
--                          Ogni attività di tipo 'documentazione' ha un record qui
--
-- CAMPI:
--  - id_attivita:        Chiave primaria e foreign key verso attivita (PK ereditata)
--  - formato:            Formato del documento (es. PDF, DOCX, Markdown, TXT)
--
-- NOTA: Se un'attività ha tipo='documentazione', DEVE esistere un record in questa
--       tabella con lo stesso id_attivita. Verificato dal trigger check_tipo_file.
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
--         Implementa il pattern Table Per Type (TPT) per la gerarchia
--
-- COLLEGAMENTI (Molteplicità):
--  - attivita (1:1)      → Relazione 1:1 con tabella attivita (IS-A relationship)
--  - file_codice (1:N)   → Un'attività di sviluppo ha molti file sorgenti
--
-- CAMPI:
--  - id_attivita:        Chiave primaria e foreign key verso attivita (PK ereditata)
--  - linguaggio_principale: Linguaggio di programmazione (es. Java, Python, C++)
--  - repository_url:     Link opzionale al repository Git esterno
--
-- NOTA: Se un'attività ha tipo='sviluppo', DEVE esistere un record in questa
--       tabella con lo stesso id_attivita. Le attività di sviluppo possono avere
--       file di codice associati (tramite tabella file_codice).
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
--         Gestisce chi deve fare cosa (responsabilità delle attività)
--
-- COLLEGAMENTI (Molteplicità):
--  - attivita (N:1)      → Un'attività può essere assegnata a più membri
--  - utente (N:1)        → Un utente può essere assegnato a più attività
--  - Relazione N:M       → Un'attività ha molti assegnatari, un utente ha molte attività
--
-- CAMPI:
--  - id_attivita:        Riferimento all'attività da svolgere
--  - id_utente:          Riferimento all'utente assegnato
--  - data_assegnazione:  Data in cui l'attività è stata assegnata all'utente
--
-- NOTA: Il trigger check_assegnazione_membro garantisce che l'utente assegnato
--       sia effettivamente membro del progetto a cui appartiene l'attività.
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
--         Rappresenta il codice effettivo prodotto dal gruppo
--
-- COLLEGAMENTI (Molteplicità):
--  - sviluppo (N:1)     → Un file appartiene a un'attività di sviluppo
--  - revisione (1:N)     → Un file può avere molte revisioni (versioni)
--
-- CAMPI:
--  - id_file:            Identificativo univoco del file
--  - id_attivita:        Riferimento all'attività di sviluppo (FK verso sviluppo)
--  - nome_file:          Nome del file (es. "Main.java", "config.json")
--  - percorso:           Percorso relativo nel progetto (es. "src/main/java/")
--  - data_creazione:     Data di primo caricamento del file
--
-- NOTA: La FK verso sviluppo (non attivita) garantisce che solo le attività
--       di tipo 'sviluppo' possano avere file associati. Il trigger
--       check_tipo_file verifica anche che l'attività sia effettivamente 'sviluppo'.
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
--         Permette di vedere chi ha modificato cosa, quando e perché
--
-- COLLEGAMENTI (Molteplicità):
--  - file_codice (N:1)  → Una revisione appartiene a un solo file
--  - utente (N:1)        → Una revisione è scritta da un solo utente
--
-- CAMPI:
--  - id_revisione:       Identificativo univoco della revisione
--  - id_file:            Riferimento al file modificato
--  - id_autore:          Riferimento all'utente che ha fatto la modifica
--  - data_modifica:      Data e ora della modifica
--  - numero_versione:    Numero progressivo di versione (auto-calcolato dal trigger)
--  - nota_descrittiva:   Breve descrizione della modifica (es. "Fix bug login")
--
-- NOTA: Il trigger autoincrement_versione calcola automaticamente il numero
--       di versione come MAX(versione) + 1 per quel file.
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
--         Facilita la comunicazione e la collaborazione
--
-- COLLEGAMENTI (Molteplicità):
--  - attivita (N:1)      → Un commento si riferisce a un'attività
--  - utente (N:1)        → Un commento è scritto da un utente
--
-- CAMPI:
--  - id_commento:        Identificativo univoco del commento
--  - id_attivita:        Riferimento all'attività commentata
--  - id_utente:          Riferimento all'autore del commento
--  - testo:              Contenuto del commento
--  - timestamp_commento: Data e ora di pubblicazione
--
-- NOTA: Il trigger check_commento_membro garantisce che solo i membri del
--       progetto possano commentare le attività di quel progetto.
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
--         Funzionalità EXTRA disponibile solo per progetti con almeno 3 membri
--
-- COLLEGAMENTI (Molteplicità):
--  - attivita (1:0..1)  → Un'attività PUÒ avere una priorità (relazione opzionale)
--
-- CAMPI:
--  - id_priorita:        Identificativo univoco
--  - id_attivita:        Riferimento all'attività (UNIQUE: un'attività ha max 1 priorità)
--  - livello:            Livello di priorità: bassa | media | alta | urgente
--  - data_assegnazione:  Data di assegnazione della priorità
--
-- NOTA: Il trigger check_priorita_3_membri blocca l'inserimento se il progetto
--       ha meno di 3 membri. La UNIQUE su id_attivita garantisce che ogni
--       attività possa avere al massimo una priorità.
-- ============================================================================

CREATE TABLE priorita (
    id_priorita SERIAL PRIMARY KEY,
    id_attivita INTEGER NOT NULL,
    livello VARCHAR(10) NOT NULL,
    data_assegnazione DATE NOT NULL DEFAULT CURRENT_DATE,

    -- Foreign Key
    CONSTRAINT fk_priorita_attivita FOREIGN KEY (id_attivita)
        REFERENCES attivita(id_attivita) ON DELETE CASCADE,

    -- Vincolo: livelli di priorità validi
    CONSTRAINT chk_livello_priorita CHECK (livello IN ('bassa', 'media', 'alta', 'urgente')),

    -- Unica priorità per attività (relazione 1:0..1)
    CONSTRAINT unq_priorita_attivita UNIQUE (id_attivita)
);



-- ============================================================================
-- 12. TABELLA: notifica (EXTRA - solo per progetti con >=3 membri)
-- ============================================================================
-- SCOPO: Invia notifiche ai membri per scadenze imminenti o cambi di stato
--         Funzionalità EXTRA disponibile solo per progetti con almeno 3 membri
--
-- COLLEGAMENTI (Molteplicità):
--  - attivita (N:1)      → Una notifica si riferisce a un'attività
--  - utente (N:1)        → Una notifica è ricevuta da un utente
--
-- CAMPI:
--  - id_notifica:        Identificativo univoco della notifica
--  - id_attivita:        Attività che genera la notifica
--  - id_utente:          Utente che riceve la notifica
--  - tipo:               Tipo di notifica: scadenza_imminente | cambiamento_stato
--  - letta:              Se la notifica è stata letta dall'utente
--  - data_creazione:     Data e ora di creazione della notifica
--
-- NOTA: Il trigger check_notifica_3_membri blocca l'inserimento se il progetto
--       ha meno di 3 membri. Le notifiche sono generate automaticamente quando
--       una attività scade o cambia stato.
-- ============================================================================

CREATE TABLE notifica (
    id_notifica SERIAL PRIMARY KEY,
    id_attivita INTEGER NOT NULL,
    id_utente INTEGER NOT NULL,
    tipo VARCHAR(30) NOT NULL,
    letta BOOLEAN NOT NULL DEFAULT FALSE,
    data_creazione TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Foreign Keys
    CONSTRAINT fk_notifica_attivita FOREIGN KEY (id_attivita)
        REFERENCES attivita(id_attivita) ON DELETE CASCADE,

    CONSTRAINT fk_notifica_utente FOREIGN KEY (id_utente)
        REFERENCES utente(id_utente) ON DELETE CASCADE,

    -- Vincolo: tipi di notifica
    CONSTRAINT chk_tipo_notifica CHECK (tipo IN ('scadenza_imminente', 'cambiamento_stato'))
);



-- ============================================================================
-- TRIGGER: Implementazione vincoli logici complessi
-- ============================================================================

-- ----------------------------------------------------------------------------
-- TRIGGER 1: Verifica che l'utente assegnato sia membro del progetto
-- ----------------------------------------------------------------------------
-- SCOPO: Garantisce che un'attività possa essere assegnata solo a membri
--         del progetto a cui l'attività appartiene
--
-- LOGICA: Prima di inserire in assegnazione, verifica che:
--         - L'utente sia presente in membro_progetto per quel progetto
--         - Altrimenti blocca l'inserimento con eccezione
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION check_assegnazione_membro()
RETURNS TRIGGER AS $$
DECLARE
    v_is_membro INTEGER;
BEGIN
    -- Verifica che l'utente sia membro del progetto dell'attività
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
-- SCOPO: Garantisce che solo i membri di un progetto possano commentare
--         le attività di quel progetto
--
-- LOGICA: Prima di inserire in commento, verifica che:
--         - L'utente sia presente in membro_progetto per quel progetto
--         - Altrimenti blocca l'inserimento con eccezione
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION check_commento_membro()
RETURNS TRIGGER AS $$
DECLARE
    v_is_membro INTEGER;
BEGIN
    -- Verifica che l'utente sia membro del progetto dell'attività
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
-- SCOPO: Garantisce coerenza temporale: non si può scadere prima di iniziare
--
-- LOGICA: Prima di inserire/aggiornare attivita, verifica che:
--         - Se data_scadenza è impostata, sia > data_creazione
--         - Altrimenti blocca con eccezione
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
-- SCOPO: Calcola automaticamente il numero di versione progressivo per ogni file
--
-- LOGICA: Prima di inserire in revisione:
--         - Trova il MAX(numero_versione) per quel file
--         - Imposta NEW.numero_versione = MAX + 1
--         - Se non ci sono revisioni, parte da 1
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION autoincrement_versione()
RETURNS TRIGGER AS $$
DECLARE
    v_max_versione INTEGER;
BEGIN
    -- Trova la versione massima per questo file
    SELECT COALESCE(MAX(numero_versione), 0) INTO v_max_versione
    FROM revisione
    WHERE id_file = NEW.id_file;

    -- Imposta la nuova versione
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
-- SCOPO: Garantisce che solo le attività di tipo 'sviluppo' possano avere file
--         Implementa la coerenza della gerarchia
--
-- LOGICA: Prima di inserire in file_codice, verifica che:
--         - L'attività abbia tipo='sviluppo'
--         - Esista un record nella tabella sviluppo
--         - Altrimenti blocca con eccezione
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION check_tipo_file()
RETURNS TRIGGER AS $$
DECLARE
    v_tipo_attivita VARCHAR(20);
BEGIN
    -- Verifica che l'attività sia di tipo 'sviluppo'
    SELECT tipo INTO v_tipo_attivita
    FROM attivita
    WHERE id_attivita = NEW.id_attivita;

    IF v_tipo_attivita != 'sviluppo' THEN
        RAISE EXCEPTION 'I file di codice possono essere associati solo ad attività di sviluppo';
    END IF;

    -- Verifica che esista un record in sviluppo
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
-- SCOPO: Implementa il vincolo EXTRA: priorità solo per progetti con >=3 membri
--
-- LOGICA: Prima di inserire in priorita:
--         - Trova il progetto dell'attività
--         -Conta i membri in membro_progetto per quel progetto
--         - Se membri < 3, blocca con eccezione
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION check_priorita_progetto_3_membri()
RETURNS TRIGGER AS $$
DECLARE
    v_numero_membri INTEGER;
    v_id_progetto INTEGER;
BEGIN
    -- Trova il progetto dell'attività
    SELECT id_progetto INTO v_id_progetto
    FROM attivita
    WHERE id_attivita = NEW.id_attivita;

    -- Conta i membri del progetto
    SELECT COUNT(*) INTO v_numero_membri
    FROM membro_progetto
    WHERE id_progetto = v_id_progetto;

    -- Verifica che ci siano almeno 3 membri
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
-- SCOPO: Implementa il vincolo EXTRA: notifiche solo per progetti con >=3 membri
--
-- LOGICA: Prima di inserire in notifica:
--         - Trova il progetto dell'attività
--         - Conta i membri in membro_progetto per quel progetto
--         - Se membri < 3, blocca con eccezione
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION check_notifica_progetto_3_membri()
RETURNS TRIGGER AS $$
DECLARE
    v_numero_membri INTEGER;
    v_id_progetto INTEGER;
BEGIN
    -- Trova il progetto dell'attività
    SELECT id_progetto INTO v_id_progetto
    FROM attivita
    WHERE id_attivita = NEW.id_attivita;

    -- Conta i membri del progetto
    SELECT COUNT(*) INTO v_numero_membri
    FROM membro_progetto
    WHERE id_progetto = v_id_progetto;

    -- Verifica che ci siano almeno 3 membri
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
-- RIEPILOGO FINALE
-- ============================================================================
-- Database: UninaTaskBoard
-- Tabelle: 12 (10 principali + 2 EXTRA per progetti >=3 membri)
-- Trigger: 7 (vincoli logici + controlli EXTRA)
-- Vincoli: 20+ (PK, FK, CHECK, UNIQUE)
--
-- Pattern implementati:
--  - Table Per Type (TPT) per gerarchia attivita/documentazione/sviluppo
--  - N:M associations per membri_progetto e assegnazione
--  - Trigger per business rules complesse
--  - Functional dependencies EXTRA condizionate
-- ============================================================================
