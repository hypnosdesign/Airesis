# Aggiunge la gestione dei tag a qualsiasi modello (Proposal, Group).
#
# I tag sono memorizzati in minuscolo senza punti e gestiti tramite join table specifica
# (es. `proposal_tags`, `group_tags`).
#
# Il flag `@resaving` è usato da alcuni callback per eseguire un secondo salvataggio
# (es. aggiornamento counter cache) senza innescare di nuovo `save_tags` — prevenendo
# un loop infinito o la sovrascrittura dei tag appena salvati.
module Taggable
  extend ActiveSupport::Concern

  included do
    # Il guard `not_resaving?` impedisce loop se il modello viene salvato due volte nello stesso ciclo.
    before_save :save_tags, if: :not_resaving?
  end

  # Lista dei tag come stringa CSV separata da virgola.
  # Memoizzata: restituisce sempre lo stesso oggetto per la durata dell'istanza.
  #
  # @return [String] es. "democrazia, partecipazione, voto"
  def tags_list
    @tags_list ||= tags.map(&:text).join(', ')
  end

  # Alias di `tags_list` — mantenuto per compatibilità con le view che usano `tags_list_json`.
  #
  # @return [String]
  def tags_list_json
    @tags_list ||= tags.map(&:text).join(', ')
  end

  # Serializzazione dei tag per i widget di autocomplete (tokeninput, select2).
  # Usa il testo del tag sia come `id` che come `name` perché i tag non hanno un ID separato dall'utente.
  #
  # @return [String] JSON array di {id, name}
  def tags_data
    tags.map { |t| { id: t.text, name: t.text } }.to_json
  end

  attr_writer :tags_list

  # HTML con i tag come link cliccabili alla pagina di listing per tag.
  # Restituisce HTML non escaped — usare solo in contesti trusted (view ERB con `html_safe`).
  #
  # @return [String] HTML
  def tags_with_links
    tags.collect { |t| "<a href=\"/tags/#{t.text.strip}\">#{t.text.strip}</a>" }.join(', ')
  end

  # Sincronizza i tag del record dalla stringa `@tags_list` (assegnata dal form).
  # Normalizza ogni tag: trim, lowercase, rimozione punti.
  # Usa `find_or_create_by` per evitare duplicati: i tag sono condivisi tra tutti i record.
  # Assegna i tag via `tag_ids=` (una sola query UPDATE invece di N INSERT/DELETE).
  #
  # @return [void]
  def save_tags
    return unless @tags_list

    tids = []
    @tags_list.split(/,/).each do |tag|
      stripped = tag.strip.downcase.delete('.') # normalizzazione: "Democrazia." → "democrazia"
      t = Tag.find_or_create_by(text: stripped)
      tids << t.id
    end
    self.tag_ids = tids
  end

  # Guard per il `before_save`: restituisce false se il modello è in un ciclo di ri-salvataggio.
  # Impostare `@resaving = true` prima di un `save` secondario per saltare `save_tags`.
  #
  # @return [Boolean]
  def not_resaving?
    !@resaving
  end
end
