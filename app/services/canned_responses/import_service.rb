class CannedResponses::ImportService
  def initialize(account, file)
    @account = account
    @file = file
  end

  def perform
    xlsx = Roo::Excelx.new(@file.path)
    headers = xlsx.row(1).map { |h| h.to_s.strip.downcase.gsub(' ', '_') }
    
    created_count = 0
    updated_count = 0
    errors = []

    ActiveRecord::Base.transaction do
      (2..xlsx.last_row).each do |i|
        row = Hash[[headers, xlsx.row(i)].transpose]
        
        # Skip empty rows
        next if row['short_code'].blank? || row['content'].blank?

        canned_response = nil
        if row['id'].present?
          canned_response = @account.canned_responses.find_by(id: row['id'])
        end
        
        canned_response ||= @account.canned_responses.find_by(short_code: row['short_code']) || @account.canned_responses.new
        
        is_new = canned_response.new_record?
        
        canned_response.short_code = row['short_code']
        canned_response.content = row['content']
        
        if canned_response.save
          is_new ? created_count += 1 : updated_count += 1
        else
          errors << "Row #{i}: #{canned_response.errors.full_messages.join(', ')}"
        end
      end
    end

    {
      created_count: created_count,
      updated_count: updated_count,
      errors: errors
    }
  rescue StandardError => e
    {
      created_count: 0,
      updated_count: 0,
      errors: ["Invalid file format or corrupted Excel file: #{e.message}"]
    }
  end
end
