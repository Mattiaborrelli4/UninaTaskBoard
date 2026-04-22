# UninaTaskBoard – Documentazione Basi di Dati
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

## 3. Schema Logico

### Tabella: `utente`

Contiene le informazioni di tutti gli utenti registrati alla piattaforma.

| Colonna | Tipo | Vincoli | Descrizione |
|---|---|---|---|
| `id_utente` | SERIAL | PK | Identificatore univoco |
| `matricola` | VARCHAR(10) | UNIQUE, NOT NULL | Matricola universitaria |
| `nome` | VARCHAR(50) | NOT NULL | Nome dell'utente |
| `cognome` | VARCHAR(50) | NOT NULL | Cognome dell'utente |
| `email` | VARCHAR(100) | UNIQUE, NOT NULL | Email istituzionale |
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
| `ruolo` | VARCHAR(20) | NOT NULL, CHECK IN ('creatore','membro') | Ruolo nel progetto |
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
| `stato` | VARCHAR(20) | NOT NULL, CHECK IN ('non_iniziata','in_corso','completata') | Stato corrente |
| `tipo` | VARCHAR(20) | NOT NULL, CHECK IN ('documentazione','sviluppo') | Tipo di attività |

---

### Tabella: `sviluppo`

Specializzazione di `attivita` per le attività di tipo sviluppo. Estende con dati specifici del codice.

| Colonna | Tipo | Vincoli | Descrizione |
|---|---|---|---|
| `id_attivita` | INTEGER | PK, FK → attivita(id_attivita) | Riferimento all'attività padre |
| `linguaggio_principale` | VARCHAR(50) | | Linguaggio di programmazione principale usato |
| `repository_url` | VARCHAR(255) | | Link opzionale al repository esterno |

---

### Tabella: `documentazione`

Specializzazione di `attivita` per le attività di tipo documentazione.

| Colonna | Tipo | Vincoli | Descrizione |
|---|---|---|---|
| `id_attivita` | INTEGER | PK, FK → attivita(id_attivita) | Riferimento all'attività padre |
| `formato` | VARCHAR(30) | | Formato del documento (es. PDF, DOCX, Markdown) |

---

### Tabella: `assegnazione`

Tabella ponte N:M tra attività e utenti. Un'attività può essere assegnata a più membri.

| Colonna | Tipo | Vincoli | Descrizione |
|---|---|---|---|
| `id_attivita` | INTEGER | PK, FK → attivita(id_attivita) | Attività assegnata |
| `id_utente` | INTEGER | PK, FK → utente(id_utente) | Membro responsabile |
| `data_assegnazione` | DATE | NOT NULL, DEFAULT CURRENT_DATE | Data dell'assegnazione |

> **Vincolo logico (Trigger):** l'utente assegnato deve essere membro del progetto a cui appartiene l'attività.

---

### Tabella: `file_codice`

Rappresenta un file sorgente associato a un'attività di sviluppo.

| Colonna | Tipo | Vincoli | Descrizione |
|---|---|---|---|
| `id_file` | SERIAL | PK | Identificatore univoco |
| `id_attivita` | INTEGER | FK → sviluppo(id_attivita), NOT NULL | Attività di sviluppo di appartenenza |
| `nome_file` | VARCHAR(100) | NOT NULL | Nome del file (es. Main.java) |
| `percorso` | VARCHAR(255) | | Percorso relativo nel progetto |
| `data_creazione` | DATE | NOT NULL, DEFAULT CURRENT_DATE | Data di primo caricamento |

---

### Tabella: `revisione`

Storico delle revisioni di un file di codice. Ogni modifica viene tracciata.

| Colonna | Tipo | Vincoli | Descrizione |
|---|---|---|---|
| `id_revisione` | SERIAL | PK | Identificatore univoco |
| `id_file` | INTEGER | FK → file_codice(id_file), NOT NULL | File modificato |
| `id_autore` | INTEGER | FK → utente(id_utente), NOT NULL | Chi ha effettuato la modifica |
| `data_modifica` | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | Data e ora della modifica |
| `numero_versione` | INTEGER | NOT NULL | Numero progressivo di versione |
| `nota_descrittiva` | TEXT | NOT NULL | Breve descrizione della modifica effettuata |

> **Vincolo logico (Trigger):** il numero di versione deve essere incrementale per ogni file.

---

### Tabella: `commento`

Commenti lasciati dai membri su qualsiasi attività.

| Colonna | Tipo | Vincoli | Descrizione |
|---|---|---|---|
| `id_commento` | SERIAL | PK | Identificatore univoco |
| `id_attivita` | INTEGER | FK → attivita(id_attivita), NOT NULL | Attività commentata |
| `id_utente` | INTEGER | FK → utente(id_utente), NOT NULL | Autore del commento |
| `testo` | TEXT | NOT NULL | Contenuto del commento |
| `timestamp_commento` | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | Data e ora del commento |

> **Vincolo logico (Trigger):** l'utente che commenta deve essere membro del progetto a cui appartiene l'attività.

---

## 4. Trigger e Procedure Previste

### Trigger obbligatori

| Nome | Evento | Descrizione |
|---|---|---|
| `check_assegnazione_membro` | BEFORE INSERT su `assegnazione` | Verifica che l'utente da assegnare sia membro del progetto dell'attività |
| `check_commento_membro` | BEFORE INSERT su `commento` | Verifica che l'utente che commenta sia membro del progetto |
| `check_scadenza_attivita` | BEFORE INSERT/UPDATE su `attivita` | Verifica che la data di scadenza sia successiva alla data di creazione |
| `autoincrement_versione` | BEFORE INSERT su `revisione` | Calcola automaticamente il numero di versione come MAX + 1 per quel file |
| `check_tipo_file` | BEFORE INSERT su `file_codice` | Verifica che l'attività associata sia di tipo `sviluppo` e sia presente nella tabella `sviluppo` |

### Procedure consigliate

| Nome | Descrizione |
|---|---|
| `aggiungi_membro_progetto` | Aggiunge un utente a un progetto, gestendo duplicati e ruoli |
| `cambia_stato_attivita` | Aggiorna lo stato di un'attività con validazione della transizione |
| `get_report_progetto` | Restituisce statistiche di un progetto: totale attività, completate, in corso, revisioni medie per file |
| `get_attivita_per_membro` | Ritorna tutte le attività assegnate a un utente in un dato progetto |

---

## 5. Considerazioni sulla Progettazione

### Perché certi attributi stanno in certe tabelle

**`ruolo` in `membro_progetto` e non in `utente`**
Il ruolo non è una proprietà fissa della persona, ma dipende dal contesto del progetto. Lo stesso utente può essere *creatore* in un progetto e semplice *membro* in un altro. Inserirlo in `utente` avrebbe significato avere un solo ruolo globale per persona, il che è concettualmente errato. Collocarlo in `membro_progetto` permette di avere ruoli diversi per ogni coppia utente-progetto.

**`linguaggio_principale` e `repository_url` in `sviluppo` e non in `attivita`**
Questi attributi hanno senso solo per le attività che riguardano codice sorgente. Inserirli in `attivita` avrebbe prodotto valori NULL obbligatori per tutte le attività di documentazione, sporcando lo schema. Separandoli nella tabella figlia `sviluppo`, ogni tabella contiene solo attributi coerenti con il suo dominio.

**`formato` in `documentazione` e non in `attivita`**
Stesso ragionamento: il formato (PDF, DOCX, Markdown...) è una caratteristica che appartiene solo ai documenti, non alle attività di sviluppo. Tenerlo separato rende lo schema più pulito e le query più espressive.

**`nota_descrittiva` in `revisione` e non in `file_codice`**
La nota descrive una singola operazione di modifica, non il file nel suo complesso. Un file accumula nel tempo molte revisioni, ognuna con la sua motivazione specifica. Mettere la nota in `file_codice` avrebbe permesso di descrivere solo lo stato attuale, perdendo tutto lo storico.

**`data_ingresso` in `membro_progetto` e non in `utente`**
La data di ingresso si riferisce al momento in cui un utente è entrato in uno specifico progetto, non a quando si è registrato alla piattaforma. Un utente entra in momenti diversi in progetti diversi, quindi l'informazione appartiene alla relazione, non all'entità.

---

### Scelta della gerarchia per le attività

La gerarchia `attivita` → `sviluppo` / `documentazione` è implementata con il pattern **Table per Type (TPT)**: una tabella padre con gli attributi comuni e due tabelle figlie con gli attributi specifici. Questa scelta garantisce integrità referenziale e semplicità nelle query generali sulle attività.

L'attributo `tipo` nella tabella `attivita` funge da discriminatore e viene verificato tramite trigger per garantire coerenza con la tabella figlia popolata.

### Scelta del DBMS

Come indicato nelle specifiche del progetto, si utilizza **PostgreSQL** (scelta consigliata). Le funzionalità specifiche di PostgreSQL utilizzate includono: `SERIAL` per le chiavi primarie auto-incrementali, `CURRENT_TIMESTAMP` per i timestamp automatici, e la sintassi PL/pgSQL per trigger e procedure.

### Integrità referenziale

Tutte le chiavi esterne usano `ON DELETE CASCADE` quando la cancellazione del padre deve propagarsi ai figli (es. cancellare un progetto rimuove le attività e le assegnazioni), e `ON DELETE RESTRICT` quando la cancellazione non deve essere permessa se esistono dipendenze (es. non si può cancellare un utente se ha revisioni registrate).

---

*Documento redatto per il corso di Basi di Dati – Gr. 1 | Federico II Napoli | A.A. 2025/2026*
