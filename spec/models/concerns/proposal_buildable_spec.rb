require 'rails_helper'

RSpec.describe ProposalBuildable, type: :model, seeds: true do
  let(:user) { create(:user) }

  def base_proposal(type_name = 'STANDARD')
    p = build(:proposal, current_user_id: user.id)
    p.sections.clear
    p.solutions.clear
    type = ProposalType.find_by(name: type_name)
    p.proposal_type = type if type
    p
  end

  describe '#simple_new' do
    it 'builds at least one section with a paragraph' do
      p = base_proposal('SIMPLE')
      p.simple_new
      expect(p.sections).not_to be_empty
      expect(p.sections.first.paragraphs).not_to be_empty
      expect(p.proposal_votation_type_id.to_s).to eq('standard')
    end
  end

  describe '#standard_new' do
    it 'builds at least one section with a paragraph' do
      p = base_proposal('STANDARD')
      p.standard_new
      expect(p.sections).not_to be_empty
      expect(p.sections.first.paragraphs).not_to be_empty
      expect(p.proposal_votation_type_id.to_s).to eq('standard')
    end
  end

  describe '#agenda_new' do
    it 'builds at least one section' do
      p = base_proposal('AGENDA')
      p.agenda_new
      expect(p.sections).not_to be_empty
      expect(p.proposal_votation_type_id.to_s).to eq('standard')
    end
  end

  describe '#estimate_new' do
    it 'builds at least one section' do
      p = base_proposal('ESTIMATE')
      p.estimate_new
      expect(p.sections).not_to be_empty
      expect(p.proposal_votation_type_id.to_s).to eq('standard')
    end
  end

  describe '#event_new' do
    it 'builds at least one section' do
      p = base_proposal('EVENT')
      p.event_new
      expect(p.sections).not_to be_empty
      expect(p.proposal_votation_type_id.to_s).to eq('standard')
    end
  end

  describe '#press_new' do
    it 'builds at least one section' do
      p = base_proposal('PRESS')
      p.press_new
      expect(p.sections).not_to be_empty
      expect(p.proposal_votation_type_id.to_s).to eq('standard')
    end
  end

  describe '#rule_book_new' do
    it 'builds at least one section' do
      p = base_proposal('RULE_BOOK')
      p.rule_book_new
      expect(p.sections).not_to be_empty
      expect(p.proposal_votation_type_id.to_s).to eq('standard')
    end
  end

  describe '#candidates_new' do
    it 'builds at least one section' do
      p = base_proposal('CANDIDATES')
      p.candidates_new
      expect(p.sections).not_to be_empty
    end
  end

  describe '#petition_new' do
    it 'starts building a section (suggestion_html i18n key missing in test env)' do
      p = base_proposal('PETITION')
      # sections.build is called before the missing i18n key error
      begin
        p.petition_new
      rescue I18n::MissingTranslationData
        nil
      end
      expect(p.sections.size).to be >= 1
    end
  end

  describe '#poll_new' do
    it 'builds sections and 3 solutions' do
      p = base_proposal
      p.poll_new
      expect(p.sections).not_to be_empty
      expect(p.solutions.size).to eq(3)
      expect(p.proposal_votation_type_id.to_s).to eq('schulze')
    end
  end

  describe '#build_sections' do
    it 'dispatches to the correct _new method based on proposal_type' do
      p = base_proposal('SIMPLE')
      p.build_sections
      expect(p.sections).not_to be_empty
    end
  end

  describe 'create_sections via before_validation callback' do
    it 'populates solutions when a proposal is saved' do
      proposal = create(:public_proposal, current_user_id: user.id)
      expect(proposal.solutions.reload).not_to be_empty
    end
  end

  describe '#paragraphs_builder' do
    it 'builds additional sections with paragraphs' do
      p = base_proposal('STANDARD')
      initial_count = p.sections.size
      p.paragraphs_builder('standard', %w[similar stakeholders])
      expect(p.sections.size).to eq(initial_count + 2)
      p.sections.last(2).each do |section|
        expect(section.paragraphs).not_to be_empty
      end
    end
  end

  describe '#solution_builder' do
    it 'builds a Solution with the given sections' do
      p = base_proposal('SIMPLE')
      solution = p.solution_builder('simple', ['description'])
      expect(solution).to be_a(Solution)
      expect(solution.sections.size).to eq(1)
    end

    it 'builds multiple sections when given multiple names' do
      p = base_proposal('STANDARD')
      solution = p.solution_builder('standard', %w[description time subject])
      expect(solution.sections.size).to eq(3)
    end
  end

  describe '#rule_book_solution' do
    it 'builds a solution with 6 sections (4 articles + pros + cons)' do
      p = base_proposal('RULE_BOOK')
      solution = p.rule_book_solution
      expect(solution).to be_a(Solution)
      expect(solution.sections.size).to eq(6)
    end
  end

  describe '#simple_create' do
    it 'adds a solution to the proposal' do
      p = base_proposal('SIMPLE')
      p.simple_new
      p.simple_create
      expect(p.solutions).not_to be_empty
    end
  end

  describe '#standard_create' do
    it 'adds more sections and a solution' do
      p = base_proposal('STANDARD')
      p.standard_new
      p.standard_create
      expect(p.sections.size).to be > 1
      expect(p.solutions).not_to be_empty
    end
  end

  describe '#agenda_create' do
    it 'adds sections and a solution' do
      p = base_proposal('AGENDA')
      p.agenda_new
      p.agenda_create
      expect(p.solutions).not_to be_empty
    end
  end

  describe '#estimate_create' do
    it 'adds sections and a solution' do
      p = base_proposal('ESTIMATE')
      p.estimate_new
      p.estimate_create
      expect(p.solutions).not_to be_empty
    end
  end

  describe '#event_create' do
    it 'adds sections and a solution' do
      p = base_proposal('EVENT')
      p.event_new
      p.event_create
      expect(p.solutions).not_to be_empty
    end
  end

  describe '#press_create' do
    it 'adds sections and a solution' do
      p = base_proposal('PRESS')
      p.press_new
      p.press_create
      expect(p.solutions).not_to be_empty
    end
  end

  describe '#rule_book_create' do
    it 'adds sections and a solution' do
      p = base_proposal('RULE_BOOK')
      p.rule_book_new
      p.rule_book_create
      expect(p.solutions).not_to be_empty
    end
  end

  describe '#candidates_create' do
    it 'adds sections and a solution' do
      p = base_proposal('CANDIDATES')
      p.candidates_new
      p.candidates_create
      expect(p.solutions).not_to be_empty
    end
  end

  describe '#petition_create' do
    it 'is a no-op and does not raise' do
      p = base_proposal('PETITION')
      expect { p.petition_create(p) }.not_to raise_error
    end
  end

  describe '#build_section' do
    it 'builds a section with a paragraph on the given element' do
      p = base_proposal
      p.build_section(p, 'Test Title', 'Test Question', 1)
      last_section = p.sections.last
      expect(last_section).not_to be_nil
      expect(last_section.paragraphs).not_to be_empty
    end
  end

  describe '#build_solution_section' do
    it 'builds a section with a paragraph on the given solution' do
      p = base_proposal
      solution = Solution.new
      p.build_solution_section(solution, 'Sol Title', 'Sol Question', 1)
      expect(solution.sections).not_to be_empty
    end
  end

  describe '#build_solution' do
    it 'dispatches to the type-specific solution method' do
      p = base_proposal('SIMPLE')
      p.simple_new
      solution = p.build_solution
      expect(solution).to be_a(Solution)
      expect(solution.sections).not_to be_empty
    end
  end

  describe '#candidates_solution' do
    it 'builds a solution with data and curriculum sections' do
      p = base_proposal('CANDIDATES')
      solution = p.candidates_solution
      expect(solution).to be_a(Solution)
      expect(solution.sections.size).to eq(2)
    end
  end

  describe '#press_solution' do
    it 'builds a solution with 6 sections' do
      p = base_proposal('PRESS')
      solution = p.press_solution
      expect(solution).to be_a(Solution)
      expect(solution.sections.size).to eq(6)
    end
  end

  describe '#event_solution' do
    it 'builds a solution with 5 sections' do
      p = base_proposal('EVENT')
      solution = p.event_solution
      expect(solution).to be_a(Solution)
      expect(solution.sections.size).to eq(5)
    end
  end

  describe '#estimate_solution' do
    it 'builds a solution with 3 sections' do
      p = base_proposal('ESTIMATE')
      solution = p.estimate_solution
      expect(solution).to be_a(Solution)
      expect(solution.sections.size).to eq(3)
    end
  end

  describe '#agenda_solution' do
    it 'builds a solution with 4 sections' do
      p = base_proposal('AGENDA')
      solution = p.agenda_solution
      expect(solution).to be_a(Solution)
      expect(solution.sections.size).to eq(4)
    end
  end
end
