# Configura la ricerca full-text PostgreSQL per le proposte tramite `pg_search`.
# Separato in un concern per tenere `Proposal` leggibile.
module ProposalSearchable
  extend ActiveSupport::Concern

  included do
    include PgSearch::Model

    # Ricerca principale per titolo (peso A) e contenuto (peso B).
    # `normalization: 2` normalizza il ranking per la lunghezza del documento (evita bias verso testi lunghi).
    # `prefix: true` permette ricerche parziali ("democr" trova "democrazia").
    # `dictionary: 'english'` usa il dizionario inglese per stemming — limitazione per testi italiani.
    pg_search_scope :search,
                    against: { title: 'A', content: 'B' },
                    order_within_rank: 'proposals.updated_at DESC, proposals.created_at DESC',
                    using: { tsearch: { normalization: 2,
                                        prefix: true,
                                        dictionary: 'english' } }

    # Ricerca per similarità: include anche i tag associati.
    # `any_word: true` usa la modalità OR tra i termini (più risultati, meno precisi).
    # Usato per trovare "proposte simili" nella vista di dettaglio.
    pg_search_scope :search_similar,
                    against: %i[title content],
                    associated_against: { tags: :text },
                    order_within_rank: 'proposals.updated_at DESC, proposals.created_at DESC',
                    using: { tsearch: { normalization: 2, any_word: true } }
  end
end
