# UninaTaskBoard 🎓

**Piattaforma collaborativa per gestione progetti universitari**

Progetto per il corso di **Basi di Dati** - Università degli Studi di Napoli Federico II

---

## 📋 Indice

- [Descrizione](#descrizione)
- [Caratteristiche](#caratteristiche)
- [Tecnologie](#tecnologie)
- [Struttura del Database](#struttura-del-database)
- [Installazione](#installazione)
- [Documentazione](#documentazione)

---

## 🎯 Descrizione

**UninaTaskBoard** è una piattaforma web che consente agli studenti dell'Università di organizzare e gestire attività collaborative all'interno di progetti, come ad esempio:
- Progetti di gruppo per corsi universitari
- Preparazione di esami
- Sviluppo di piccoli applicativi

Gli utenti possono creare progetti, invitare altri studenti a partecipare, definire attività, assegnare responsabilità e tracciare lo stato di avanzamento.

---

## ✨ Caratteristiche

### Funzionalità Principali
- ✅ **Gestione Progetti**: Creazione e gestione di progetti collaborativi
- ✅ **Gestione Membri**: Invito di studenti con ruoli (creatore/membro)
- ✅ **Due Tipi di Attività**:
  - 📄 **Documentazione**: PDF, DOCX, Markdown
  - 💻 **Sviluppo**: Codice sorgente con versioning
- ✅ **Assegnazione Attività**: Assegnazione di attività a più membri
- ✅ **File di Codice**: Gestione file sorgenti per attività di sviluppo
- ✅ **Sistema di Revisioni**: Tracciamento modifiche con autore, data e descrizione
- ✅ **Commenti**: Comunicazione tra membri sulle attività

### Funzionalità EXTRA (Progetti con ≥3 membri)
- ⭐ **Priorità**: Assegnazione priorità alle attività (bassa/media/alta/urgente)
- 🔔 **Notifiche**: Avvisi per scadenze imminenti e cambi di stato

---

## 🛠️ Tecnologie

| Componente | Tecnologia |
|-------------|------------|
| **Database** | PostgreSQL 14+ |
| **Linguaggio** | SQL (PL/pgSQL per trigger) |
| **Pattern ORM** | Table Per Type (TPT) per gerarchie |
| **Vincoli** | Foreign Keys, Check, Trigger |
| **Versioning** | Git + GitHub |

---

## 🗄️ Struttura del Database

### Schema ER

Il database è composto da **12 tabelle** principali:

#### Tabelle Fondamentali
1. **utente** - Studenti registrati
2. **progetto** - Progetti collaborativi
3. **membro_progetto** - Associazione N:M utenti-progetti
4. **attivita** - Attività dei progetti (tabella padre)

#### Gerarchia Attività (Table Per Type)
5. **documentazione** - Specializzazione per documenti (1:1 con attivita)
6. **sviluppo** - Specializzazione per codice (1:1 con attivita)

#### Gestione Attività
7. **assegnazione** - Chi fa cosa (N:M attività-utenti)
8. **file_codice** - File sorgenti per attività di sviluppo
9. **revisione** - Storico versioni dei file
10. **commento** - Commenti sulle attività

#### Funzionalità EXTRA
11. **priorita** - Priorità attività (solo progetti ≥3 membri)
12. **notifica** - Notifiche membri (solo progetti ≥3 membri)

### Relazioni Principali

```
utente (1:N)──< progetto
utente (N:M)──< membro_progetto >──(N:M) progetto
progetto (1:N)──< attivita
attivita (1:1)──< documentazione
attivita (1:1)──< sviluppo
sviluppo (1:N)──< file_codice (1:N)──< revisione
attivita (N:M)──< assegnazione >──(N:M) utente
attivita (1:N)──< commento
```

### Trigger Implementati

1. **check_assegnazione_membro** - Verifica che l'utente assegnato sia membro del progetto
2. **check_commento_membro** - Verifica che chi commenta sia membro del progetto
3. **check_scadenza_attivita** - Verifica che scadenza > creazione
4. **autoincrement_versione** - Auto-incrementa numero versione revisioni
5. **check_tipo_file** - Verifica che file siano solo per attività di sviluppo
6. **check_priorita_3_membri** - Blocca priorità se progetto ha <3 membri
7. **check_notifica_3_membri** - Blocca notifiche se progetto ha <3 membri

---

## 📦 Installazione

### Prerequisiti
- PostgreSQL 14+ installato
- Git installato
- Account GitHub

### Passaggi

1. **Clona il repository**
```bash
git clone https://github.com/Mattiaborrelli4/UninaTaskBoard.git
cd UninaTaskBoard
```

2. **Crea il database**
```bash
# Su Windows con psql
psql -U postgres -f CREAZIONE_TABELLE.sql

# Oppure da psql interattivo
\i CREAZIONE_TABELLE.sql
```

3. **Verifica l'installazione**
```sql
-- Verifica tabelle create
\dt

-- Verifica trigger creati
SELECT tgname FROM pg_trigger WHERE tgname LIKE 'trg_%';
```

---

## 📚 Documentazione

### File nel Repository

| File | Descrizione |
|------|-------------|
| **CREAZIONE_TABELLE.sql** | Script SQL completo per creazione database |
| **UninaTaskBoard_Database_Documentazione.md** | Documentazione tecnica completa |
| **UninaTaskBoard.drawio** | Diagramma ER (UML) in formato DrawIO |
| **Tracce-Progetti-BD-POO-2026-2027.pdf** | Traccia ufficiale del progetto |
| **README.md** | Questo file |

### Leggi la Documentazione

Per dettagli su:
- **Analisi del dominio**: Vedi `UninaTaskBoard_Database_Documentazione.md`
- **Schema logico**: Vedi sezione 2 del documento tecnico
- **Trigger e vincoli**: Vedi sezione 3 del documento tecnico
- **Considerazioni progettuali**: Vedi sezione 4 del documento tecnico

---

## 🎓 Contatti

**Studente**: Mattia Borrelli
**Corso**: Basi di Dati
**Università**: Università degli Studi di Napoli Federico II
**Anno Accademico**: 2025/2026

---

## 📝 Licenza

Questo progetto è stato realizzato per scopi educativi nel corso di Basi di Dati dell'Università degli Studi di Napoli Federico II.

---

**Made with ❤️ for Federico II University**
