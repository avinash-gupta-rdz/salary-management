# Departments and the job titles each one has. A fixed list (like Country) so
# insights never split one department into "Engineering" / "engineering" / "Engg".
# Adding a role is a one-line change here plus a salary band in EmployeeSeeder.
class Department < Data.define(:name, :job_titles)
  ALL = [
    new(name: "Engineering", job_titles: [ "Software Engineer", "Senior Software Engineer", "Engineering Manager", "QA Engineer", "DevOps Engineer" ].freeze),
    new(name: "Product", job_titles: [ "Product Manager", "Product Designer" ].freeze),
    new(name: "Sales", job_titles: [ "Account Executive", "Sales Manager" ].freeze),
    new(name: "Marketing", job_titles: [ "Marketing Specialist", "Marketing Manager" ].freeze),
    new(name: "Finance", job_titles: [ "Accountant", "Financial Analyst" ].freeze),
    new(name: "People", job_titles: [ "HR Generalist", "Recruiter" ].freeze),
    new(name: "Operations", job_titles: [ "Operations Analyst", "Customer Support Specialist" ].freeze)
  ].freeze

  def self.all
    ALL
  end

  def self.find(name)
    ALL.find { |department| department.name == name }
  end

  def self.names
    ALL.map(&:name)
  end

  def self.job_titles
    ALL.flat_map(&:job_titles)
  end
end
