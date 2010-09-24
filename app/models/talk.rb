class Talk < ActiveRecord::Base
  acts_as_paranoid

  belongs_to :room
  
  named_scope :by_time,   :order => "start_time"

  #BTE commented these out because the time() function is unavailable in
  #PostgreSQL.  They could be replaced by conditionally determining the DB.
  #named_scope :morning,   :conditions => [ "time(start_time) <  '12:00' " ]
  #named_scope :afternoon, :conditions => [ "time(start_time) >= '12:00' " ]

  # Find the current and next talk
  named_scope :active,    lambda { |*args| named_scope_active( *args ) }
  named_scope :next,      lambda { |*args| named_scope_next( *args ) }

  validates_presence_of :day, :name, :room_id, :start_time, :end_time
  validate :timecheck

  #return the best conference day for today's date
  def self.logical_day
    days = Talk.all(:select => 'distinct day').map { |t| t.day }
    today = Date.today

    if today < days.first
      return days.first
    end

    days.each do |d|
      return d if d == today
    end

    days.last
  end

  #returns all talks for today's conference
  def self.talks_for_logical_day
    self.all(:conditions => ["day = ?", self.logical_day], :include => :room, :order => "day, start_time")
  end

  #to make talk.room.name easily accessible to to_json calls
  def room_name
    room.name
  end

  def timecheck
    min = Date.new(2000,1,1)
    if start_time && end_time
      errors.add_to_base("Please set times") if start_time == min || end_time == min
      errors.add_to_base("Please set end time after start time") if end_time <= start_time
    end
  end

  def speakable_description
    "#{name}, by #{who}. . . From #{start_time_string} until #{end_time_string}"
  end
 
  def start_time_string
    start_time ? start_time.strftime("%I:%M") : "unknown"
  end

  def end_time_string
    end_time ? end_time.strftime("%I:%M") : "unknown"
  end

  private
    def self.named_scope_active( *args )
      time = args.first || Time.now
      { :conditions => [ "time(start_time) <= time(?) and time(end_time) >= time(?)", time, time ] }
    end
    
    def self.named_scope_next( *args )
      time = args.first || Time.now
      { :conditions => [ "time(start_time) >= time(?)", time ], :order => "start_time", :limit => 1 }
    end
end
