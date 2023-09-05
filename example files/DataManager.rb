
  #--------------------------------------------------------------------------
  # * Determines the Directory of Save File (New Function)
  #--------------------------------------------------------------------------
  def self.save_folder
    directory_name = ''
    if OS.windows?
      directory_name = Dir.home + "/AppData/My Game"
    elsif OS.linux?
      directory_name = Dir.home + "/.local/share/lowercasecompany-lowercasegame"
    elsif OS.mac?
      directory_name = Dir.home + "/Library/My Game"
    end
	Dir.mkdir(directory_name) unless File.exists?(directory_name)
    sprintf(directory_name)
  end
  #--------------------------------------------------------------------------
  # * Determine Existence of Save File (Replaces Existing Function)
  #--------------------------------------------------------------------------
  def self.save_file_exists?
    !Dir.glob(save_folder() + '/Save*.rvdata2').empty?
  end
  #--------------------------------------------------------------------------
  # * Create Filename (Replaces Existing Function)
  #     index : File Index
  #--------------------------------------------------------------------------
  def self.make_filename(index)
    sprintf(save_folder() + "/Save%02d.rvdata2", index + 1)
  end
