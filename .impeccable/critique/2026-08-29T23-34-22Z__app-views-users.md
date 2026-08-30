---
group: G02
phase: post_fix_iteration_3
score: 31
score_max: 40
p0: 0
p1: 1
timestamp: 2026-08-29T23-34-22Z
slug: app-views-users
---
# G02 — iterazione 3 post-fix

## Esito

Punteggio Impeccable: **31/40**. Gate non superato: **P0 0, P1 1**.

La matrice desktop/mobile ha confermato un solo `main` e H1, assenza di overflow e runtime error, target effettivi da almeno 44 px, dialog profilo corretti e contrasto minimo osservato di 5,04:1 dopo la correzione dei label.

## P1 confermato

1. Al primo utilizzo mobile dopo reload, il drawer diventava modale e isolava correttamente lo sfondo, ma il focus restava su `BODY` perché i retry terminavano prima della transizione di apertura da 200 ms. Le aperture successive funzionavano.

## P2 principali

- Statistiche utente non raggruppate, con timestamp grezzo e metriche difficili da scansionare su mobile.
- Pagine archivio `/school` e `/municipality` correttamente marcate `lang="it"`, ma senza dichiarazione nella lingua della shell.
- Popover notifiche e account senza stato `aria-expanded`/`aria-controls` sincronizzato.
- Il sottotitolo di `/users/edit` misurava 4,15:1.

## Correzioni avviate per l'iterazione successiva

- Retry focus drawer limitato a 40 frame e annullato alla chiusura/disconnessione.
- Statistiche raggruppate in sezioni e definition list, data localizzata e colonna sort interna nascosta.
- Controller dropdown condiviso con stato ARIA, tastiera, Esc e restore.
- Notice archivio solo italiano, affordance mobile per la navigazione impostazioni e contrasto sottotitolo corretto.
