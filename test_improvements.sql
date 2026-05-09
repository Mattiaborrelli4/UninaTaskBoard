-- SCRIPT DI TEST PER LE MIGLIORIE DI UninaTaskBoard
-- ============================================================================

-- 1. Inserimento Utenti (Verifica regex email)
INSERT INTO utente (matricola, nome, cognome, email, password)
VALUES ('0123456789', 'Mario', 'Rossi', 'm.rossi1@studenti.unina.it', 'pass123');

INSERT INTO utente (matricola, nome, cognome, email, password)
VALUES ('9876543210', 'Luigi', 'Verdi', 'l.verdi@studenti.unina.it', 'secure456');

INSERT INTO utente (matricola, nome, cognome, email, password)
VALUES ('1122334455', 'Anna', 'Neri', 'a.neri@studenti.unina.it', 'secret789');

-- 2. Creazione Progetto (Verifica trigger auto_membro_creatore)
INSERT INTO progetto (nome, descrizione, id_creatore)
VALUES ('Progetto Test Jules', 'Descrizione del progetto di test', 1);

-- Verifica che Mario Rossi (id 1) sia già in membro_progetto
SELECT * FROM vista_membri_progetto WHERE id_progetto = 1;

-- 3. Aggiunta membri tramite Procedura
CALL aggiungi_membro_progetto(2, 1, 'membro');
CALL aggiungi_membro_progetto(3, 1, 'membro');

-- Verifica membri totali (dovrebbero essere 3)
SELECT * FROM vista_membri_progetto WHERE id_progetto = 1;

-- 4. Creazione Attività
INSERT INTO attivita (id_progetto, titolo, descrizione, tipo)
VALUES (1, 'Sviluppo Backend', 'Implementazione API', 'sviluppo');

-- Inserimento record in sviluppo
INSERT INTO sviluppo (id_attivita, linguaggio_principale)
VALUES (1, 'PostgreSQL');

-- 5. Test Cambio Stato e Notifiche Automatiche
-- Essendo il progetto con 3 membri, dovrebbe generare notifiche
CALL cambia_stato_attivita(1, 'in_corso');

-- Verifica notifiche generate
SELECT * FROM notifica WHERE id_attivita = 1;

-- 6. Test Report Progetto
SELECT * FROM get_report_progetto(1);

-- 7. Test Vista Dettagliata
SELECT * FROM vista_attivita_dettagliata WHERE id_progetto = 1;

-- 8. Test Vincolo Priorità (>= 3 membri)
INSERT INTO priorita (id_attivita, livello)
VALUES (1, 'alta');

-- Verifica priorità
SELECT * FROM priorita WHERE id_attivita = 1;

-- 9. Fine Test
\q
