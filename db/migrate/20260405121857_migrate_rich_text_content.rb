class MigrateRichTextContent < ActiveRecord::Migration[8.1]
  def up
    # BlogPost#body: copy existing text column → ActionText
    BlogPost.find_each do |record|
      html = record.read_attribute(:body)
      next if html.blank?

      record.body = html
      record.save!(validate: false)
    end

    # Group#description and #rule_book: copy existing string columns → ActionText
    Group.find_each do |record|
      desc = record.read_attribute(:description)
      rule = record.read_attribute(:rule_book)
      record.description = desc if desc.present?
      record.rule_book = rule if rule.present?
      record.save!(validate: false)
    end

    # Frm::Post#text: copy existing text column → ActionText
    Frm::Post.find_each do |record|
      html = record.read_attribute(:text)
      next if html.blank?

      record.text = html
      record.save!(validate: false)
    end
  end

  def down
    # Irreversible — ActionText records would need to be deleted manually
    raise ActiveRecord::IrreversibleMigration
  end
end
