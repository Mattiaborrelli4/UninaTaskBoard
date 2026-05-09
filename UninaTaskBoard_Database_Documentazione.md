# UninaTaskBoard – Documentazione Basi di Dati (Migliorata)
**Corso di Studi in Informatica – Federico II**
**A.A. 2025/2026 | Traccia 3**

---

## 1. Scopo del Progetto

UninaTaskBoard è una piattaforma web per la gestione collaborativa di attività universitarie. Permette agli studenti di organizzare progetti di gruppo, preparare esami o sviluppare piccoli applicativi, tenendo traccia di tutte le attività, i file di codice e le relative revisioni.

L'obiettivo del database è modellare e persistere in modo efficiente:

- Gli utenti registrati e i progetti a cui partecipano
- Le attività di ogni progetto, con i loro stati e scadenze
- Le assegnazioni delle attività ai membri del progetto
- I file di codice associati alle attività di sviluppo e le loro revisioni nel tempo
- I commenti che i membri possono lasciare sulle attività

---

## 2. Analisi del Dominio

### 2.1 Entità principali

| Entità | Descrizione |
|---|---|
| **Utente** | Studente registrato alla piattaforma con credenziali di accesso |
| **Progetto** | Contenitore di attività, creato da un utente e condiviso con altri |
| **Membro_Progetto** | Relazione che associa un utente a un progetto con un ruolo |
| **Attività** | Unità di lavoro all'interno di un progetto, con stato e scadenza |
| **Documentazione** | Specializzazione di Attività per contenuti testuali/documentali |
| **Sviluppo** | Specializzazione di Attività per codice sorgente |
| **Assegnazione** | Relazione che assegna una o più attività a uno o più membri |
| **File_Codice** | File sorgente collegato a un'attività di sviluppo |
| **Revisione** | Storico delle modifiche apportate a un file di codice |
| **Commento** | Nota testuale lasciata da un membro su un'attività |

### 2.2 Regole di business fondamentali

1. Un utente può partecipare a più progetti e un progetto può avere più utenti (N:M).
2. Ogni attività appartiene a esattamente un progetto.
3. Un'attività può essere assegnata a più membri, ma solo se questi fanno parte del progetto.
4. Ogni attività è **o** di documentazione **o** di sviluppo (gerarchia esclusiva).
5. Solo le attività di sviluppo possono avere file di codice associati.
6. Ogni file di codice può avere zero o più revisioni nel tempo.
7. Ogni revisione è autenticata: si sa chi l'ha scritta e quando.
8. La data di scadenza di un'attività, se presente, deve essere successiva alla data di creazione.
9. Lo stato di un'attività può essere solo: `non_iniziata`, `in_corso`, `completata`.

---

## 3. Schema Logico (Migliorato con ENUM)

### Tabella: `utente`

Contiene le informazioni di tutti gli utenti registrati alla piattaforma.

| Colonna | Tipo | Vincoli | Descrizione |
|---|---|---|---|
| `id_utente` | SERIAL | PK | Identificatore univoco |
| `matricola` | VARCHAR(10) | UNIQUE, NOT NULL | Matricola universitaria |
| `nome` | VARCHAR(50) | NOT NULL | Nome dell'utente |
| `cognome` | VARCHAR(50) | NOT NULL | Cognome dell'utente |
| `email` | VARCHAR(100) | UNIQUE, NOT NULL (Regex) | Email istituzionale (@studenti.unina.it) |
| `password` | VARCHAR(255) | NOT NULL | Password cifrata |
| `data_registrazione` | DATE | NOT NULL, DEFAULT CURRENT_DATE | Data di iscrizione alla piattaforma |

---

### Tabella: `progetto`

Rappresenta un progetto collaborativo creato da un utente.

| Colonna | Tipo | Vincoli | Descrizione |
|---|---|---|---|
| `id_progetto` | SERIAL | PK | Identificatore univoco |
| `nome` | VARCHAR(100) | NOT NULL | Nome del progetto |
| `descrizione` | TEXT | | Descrizione opzionale |
| `data_creazione` | DATE | NOT NULL, DEFAULT CURRENT_DATE | Data di creazione |
| `id_creatore` | INTEGER | FK → utente(id_utente), NOT NULL | Utente che ha creato il progetto |

---

### Tabella: `membro_progetto`

Tabella ponte N:M tra utente e progetto. Registra chi partecipa a quale progetto e con quale ruolo.

| Colonna | Tipo | Vincoli | Descrizione |
|---|---|---|---|
| `id_utente` | INTEGER | PK, FK → utente(id_utente) | Membro del progetto |
| `id_progetto` | INTEGER | PK, FK → progetto(id_progetto) | Progetto di appartenenza |
| `ruolo` | ENUM | NOT NULL (`ruolo_membro`) | Ruolo nel progetto ('creatore', 'membro') |
| `data_ingresso` | DATE | NOT NULL, DEFAULT CURRENT_DATE | Data di accettazione dell'invito |

---

### Tabella: `attivita`

Entità centrale. Rappresenta ogni singola attività di un progetto.

| Colonna | Tipo | Vincoli | Descrizione |
|---|---|---|---|
| `id_attivita` | SERIAL | PK | Identificatore univoco |
| `id_progetto` | INTEGER | FK → progetto(id_progetto), NOT NULL | Progetto di appartenenza |
| `titolo` | VARCHAR(150) | NOT NULL | Titolo breve dell'attività |
| `descrizione` | TEXT | | Descrizione estesa |
| `data_creazione` | DATE | NOT NULL, DEFAULT CURRENT_DATE | Data di creazione |
| `data_scadenza` | DATE | CHECK > data_creazione | Scadenza opzionale |
| `stato` | ENUM | NOT NULL (`stato_attivita`) | Stato corrente |
| `tipo` | ENUM | NOT NULL (`tipo_attivita`) | Tipo di attività |

---

### Tabella: `priorita` (EXTRA)

| Colonna | Tipo | Vincoli | Descrizione |
|---|---|---|---|
| `id_priorita` | SERIAL | PK | Identificatore univoco |
| `id_attivita` | INTEGER | FK → attivita(id_attivita), NOT NULL (UNIQUE) | Attività associata |
| `livello` | ENUM | NOT NULL (`livello_priorita`) | Livello priorità |
| `data_assegnazione` | DATE | NOT NULL, DEFAULT CURRENT_DATE | Data assegnazione |

---

### Tabella: `notifica` (EXTRA)

| Colonna | Tipo | Vincoli | Descrizione |
|---|---|---|---|
| `id_notifica` | SERIAL | PK | Identificatore univoco |
| `id_attivita` | INTEGER | FK → attivita(id_attivita), NOT NULL | Attività sorgente |
| `id_utente` | INTEGER | FK → utente(id_utente), NOT NULL | Destinatario |
| `tipo` | ENUM | NOT NULL (`tipo_notifica`) | Tipo notifica |
| `letta` | BOOLEAN | NOT NULL, DEFAULT FALSE | Stato lettura |
| `data_creazione` | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | Data invio |

---

## 4. Trigger e Procedure Implementate

### Trigger

| Nome | Evento | Descrizione |
|---|---|---|
| `check_assegnazione_membro` | BEFORE INSERT su `assegnazione` | Verifica che l'utente sia membro del progetto |
| `check_commento_membro` | BEFORE INSERT su `commento` | Verifica che l'utente sia membro del progetto |
| `check_scadenza_attivita` | BEFORE INSERT/UPDATE su `attivita` | Verifica coerenza temporale |
| `autoincrement_versione` | BEFORE INSERT su `revisione` | Calcola versione MAX + 1 |
| `check_tipo_file` | BEFORE INSERT su `file_codice` | Verifica coerenza gerarchia sviluppo |
| `auto_membro_creatore` | AFTER INSERT su `progetto` | **(NEW)** Aggiunge automaticamente il creatore tra i membri |
| `genera_notifica_stato` | AFTER UPDATE su `attivita` | **(NEW)** Genera notifiche automatiche al cambio stato (progetti >= 3 membri) |

### Procedure e Funzioni

| Nome | Tipo | Descrizione |
|---|---|---|
| `aggiungi_membro_progetto` | PROCEDURE | Aggiunge un utente a un progetto |
| `cambia_stato_attivita` | PROCEDURE | Aggiorna lo stato di un'attività |
| `get_report_progetto` | FUNCTION | Restituisce statistiche aggregate di un progetto |

---

## 5. Miglioramenti Architetturali

1.  **Tipi ENUM**: Sostituiti i vincoli stringa con tipi enumerativi per migliori performance e pulizia.
2.  **Viste (Views)**: Introdotte `vista_attivita_dettagliata` e `vista_membri_progetto` per semplificare le query complesse.
3.  **Indici**: Aggiunti indici sulle chiavi esterne per ottimizzare le operazioni di join e ricerca.
4.  **Automazione**: Il database ora gestisce autonomamente l'iscrizione del creatore e la generazione di notifiche.

---

*Documento aggiornato dal Jules per il progetto UninaTaskBoard | A.A. 2025/2026*
