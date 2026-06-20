require 'rubygems'
require 'gosu'

TOP_COLOUR = Gosu::Color.new(0xFF1EB1FA)
BOTTOM_COLOUR = Gosu::Color::BLACK
HIGHLIGHT_COLOUR = Gosu::Color::BLUE
MAIN_COLOUR = Gosu::Color::WHITE
DARK_ACCENT = Gosu::Color.new(0xFF000d3d)
DARK_COLOUR = Gosu::Color.new(0xFF001563)

HIGHLIGHT_THICKNESS = 5

#screen params
WIDTH = 800
HEIGHT = 700

ALBUM_WIDTH = 200
ALBUM_HEIGHT = 200

TRACK_WIDTH = 320
TRACK_HEIGHT = 30

#display position
TRACK_X = 460

module ZOrder
  BACK, BACK_MID, HIGHLIGHT, MID, FRONT = *0..4
end

module Genre
  POP, CLASSIC, JAZZ, ROCK = *1..4
end

GENRE_NAMES = ['Null', 'Pop', 'Classic', 'Jazz', 'Rock']

#record definitions

#album class
class Album
  attr_accessor :artist, :title, :year, :genre, :tracks, :artwork

	def initialize (artist, title, year, genre, tracks, artwork)
		@artist = artist
    @title = title		
    @year = year
    @genre = genre
		@tracks = tracks
    @artwork = artwork
	end
end

#track class
class Track
	attr_accessor :name, :location, :duration

	def initialize (name, location, duration)
		@name = name
		@location = location
		@duration = duration
	end
end

#used for album display data
class AlbumHolder
    attr_accessor :album, :x1, :x2, :y1, :y2

	def initialize (album, x1, x2, y1, y2)
		@album = album
    @x1 = x1		
    @x2 = x2
    @y1 = y1
		@y2 = y2
	end
end

#used for track data
class TrackHolder
    attr_accessor :track, :x1, :x2, :y1, :y2

	def initialize (track, x1, x2, y1, y2)
		@track = track
    @x1 = x1		
    @x2 = x2
    @y1 = y1
		@y2 = y2
	end
end

#artwork
class ArtWork
	attr_accessor :bmp

	def initialize (file)
		@bmp = Gosu::Image.new(file)
	end
end

class MusicPlayerMain < Gosu::Window
	def initialize
	  super WIDTH, HEIGHT
	  self.caption = "Music Player"

    #font
    @track_font = Gosu::Font.new(30)
    @album_font = Gosu::Font.new(20)

    @filename = "albums.txt"

    @albums = Array.new()

    #mouse
    @mouse_down = false
    @mouse = false

    #albums
    @album_page = 0 #which page of track is being shown
    @album_holders = []
    @active_album = nil;

    #tracks
    @track_page = 0
    @track_holders = []
    @active_track = nil;

    read_albums()
    album_holder_setup()
    track_holder_setup()
	end

  #ALBUM AND TRACK

  #read albums
  def read_albums
    begin
      music_file = File.new(@filename, "r")
    rescue
      puts("File reading error. Did you spell it correctly?")
    else
      #store albums in array
      count = music_file.gets().to_i()
      i = 0
      while i < count
        @albums << read_album(music_file)
        i += 1
      end
    end

    music_file.close()
  end

  #read single album
  def read_album(_music_file)
    album_artist = _music_file.gets().chomp()
    album_title = _music_file.gets().chomp()
    album_artwork = _music_file.gets().chomp()
    album_year = _music_file.gets().chomp().to_i()
    album_genre = _music_file.gets().chomp().to_i()
    album_tracks = read_tracks(_music_file)
    album = Album.new(album_artist, album_title, album_year, album_genre, album_tracks, album_artwork)

    return album
  end

  #read tracks from album
  def read_tracks(music_file)
    #setup
	  count = music_file.gets().to_i()
  	tracks = Array.new()

    #read each track
  	i = 0
  	while i < count
  		track = read_track(music_file)
    	tracks << track
  		i += 1
  	end
  
  	return tracks
  end

  #read track
  def read_track(music_file)
	  track = Track.new(music_file.gets().chomp(), music_file.gets().chomp(), music_file.gets().chomp().to_i())
    return track
  end

  #####

  #instantiate holder displays
  def album_holder_setup()
    @album_holders = []

    #return if nothing there
    if(@albums.length == 0)
      return
    end

    if(@albums[@album_page * 4 + 0] != nil)
      ah0 = AlbumHolder.new(@albums[@album_page * 4 + 0], 20, 20 + ALBUM_WIDTH, 60, 60 + ALBUM_HEIGHT)
      @album_holders << ah0
    end
    if(@albums[@album_page * 4 + 1] != nil)
      ah1 = AlbumHolder.new(@albums[@album_page * 4 + 1], 230, 230 + ALBUM_WIDTH, 60, 60 + ALBUM_HEIGHT)
      @album_holders << ah1
    end
    if(@albums[@album_page * 4 + 2] != nil)
      ah2 = AlbumHolder.new(@albums[@album_page * 4 + 2], 20, 20 + ALBUM_WIDTH, 300, 300 + ALBUM_HEIGHT)
      @album_holders << ah2
    end
    if(@albums[@album_page * 4 + 3] != nil)
      ah3 = AlbumHolder.new(@albums[@album_page * 4 + 3], 230, 230 + ALBUM_WIDTH, 300, 300 + ALBUM_HEIGHT) #can't be looped because of potition differences
      @album_holders << ah3
    end
  end

  #instantiate holder displays
  def track_holder_setup()
    @track_holders = []

    if(@active_album == nil || @active_album.tracks.length == 0)
      return
    end

    #generate array of track holders!
    i = 0
    while (i < 12 && i < @active_album.tracks.length) #limiting at 12
      @track_holders << TrackHolder.new(@active_album.tracks[@track_page * 12 + i], TRACK_X, TRACK_X + TRACK_WIDTH, i * 40 + 60, i * 40 + 60 + TRACK_HEIGHT)
      i += 1
    end
  end

  # Detects if a 'mouse sensitive' area has been clicked on
  # i.e either an album or a track. returns true or false
  def area_clicked(leftX, rightX, closeY, farY)
    if(mouse_x >= leftX && mouse_x <= rightX && mouse_y >= closeY && mouse_y <= farY && @mouse_down)
      puts("Area clicked!")
      return true
    else
      return false
    end
  end

  #returns if hovered, and highlights area, very helpful
  def area_hovered(leftX, rightX, closeY, farY)
    if(mouse_x >= leftX && mouse_x <= rightX && mouse_y >= closeY && mouse_y <= farY)
      Gosu.draw_rect(leftX - HIGHLIGHT_THICKNESS, closeY - HIGHLIGHT_THICKNESS, rightX - leftX + 2 * HIGHLIGHT_THICKNESS, farY - closeY + 2 * HIGHLIGHT_THICKNESS, HIGHLIGHT_COLOUR, ZOrder::HIGHLIGHT, mode=:default)     
      return true
    else
      return false
    end
  end

  #album click
  def query_album_click()
    i = 0
    while (i < @album_holders.length)
      if(area_hovered(@album_holders[i].x1, @album_holders[i].x2, @album_holders[i].y1, @album_holders[i].y2))
        if(@mouse_down)#dont need to use click function since already on button
          @track_page = 0 #reset track page
          @active_album = @album_holders[i].album
          track_holder_setup()
        end
      end
      i += 1
    end
  end

  #track click
  def query_track_click()
    i = 0
    while (i < @track_holders.length)
      if(area_hovered(@track_holders[i].x1, @track_holders[i].x2, @track_holders[i].y1, @track_holders[i].y2))
        if(@mouse_down)#dont need to use click function since already on button
          #play track
          puts("Playing Track: " + @track_holders[i].track.name)
          @active_track = @track_holders[i].track
          play_track(@active_track)
        end
      end
      i += 1
    end
  end

  #switch album page
  def query_album_switch
    #left
    if(area_hovered(20, 70, 580, 630))
      if(@mouse_down)
        if(@album_page > 0)
          @album_page -= 1
          album_holder_setup()
        end
      end
    end

    #right
    if(area_hovered(380, 430, 580, 630))
      if(@mouse_down)
        @album_page += 1
        album_holder_setup()
      end
    end
  end

  #switch track page
  def query_track_switch
    #left
    if(area_hovered(460, 510, 580, 630))
      if(@mouse_down)
        if(@track_page > 0)
          @track_page -= 1
          track_holder_setup()
        end
      end
    end

    #right
    if(area_hovered(730, 780, 580, 630))
      if(@mouse_down)
        @track_page += 1
        track_holder_setup()
      end
    end
  end

  #query song controls
  def query_controls
    #pause
    if(area_hovered(680, 710, 660, 690))
      if(@mouse_down)
        if(@song != nil)
          @song.pause()
        end
      end
    end

    #resume
    if(area_hovered(720, 750, 660, 690))
      if(@mouse_down)
        if(@song != nil)
          @song.play()
        end
      end
    end

    #stop
    if(area_hovered(760, 790, 660, 690))
      if(@mouse_down)
        if(@song != nil)
          @song.stop()
        end
      end
    end
  end

  # Draws the artwork on the screen for all the albums
  def draw_albums()
    i = 0
    while (i < 4)
      #could draw a white box if it can't find the image:
      #Gosu.draw_rect(@album_holders[i].x1, @album_holders[i].y1, ALBUM_WIDTH, ALBUM_HEIGHT, MAIN_COLOUR, ZOrder::FRONT, mode=:default)
      if(@albums[@album_page * 4 + i] != nil)
        @image = Gosu::Image.new(@album_holders[i].album.artwork)
        @image.draw(@album_holders[i].x1, @album_holders[i].y1, ZOrder::FRONT)
        @album_font.draw(@album_holders[i].album.artist, @album_holders[i].x1, @album_holders[i].y2 + 10, ZOrder::FRONT, 1.0, 1.0, MAIN_COLOUR)
      end
      i += 1
    end
  end

  #select Track
  def draw_tracks(selected_album)
    #return if nothing to show :(
    if(selected_album == nil || selected_album.tracks.length == 0)
      return;
    end
          
    i = 0 #start at 0
    while (i < 12)
      if(selected_album.tracks[@track_page * 12 + i] != nil)
        draw_track(selected_album.tracks[@track_page * 12 + i].name, i * 40 + 60) #changed to just parse album instead of int            
      end
        i += 1
      end
  end

  # Takes a String title and an Integer ypos
  def draw_track(title, ypos)
    Gosu.draw_rect(TRACK_X, ypos, TRACK_WIDTH, TRACK_HEIGHT, DARK_COLOUR, ZOrder::MID, mode=:default)
  	@track_font.draw(title, TRACK_X, ypos, ZOrder::FRONT, 1.0, 1.0, MAIN_COLOUR)
  end

  #plays the requeseted track
  def play_track(track)
    #parses in track
  	@song = Gosu::Song.new(track.location)
  	@song.play(false)
  end

  #album page arrows
  def draw_album_nav
    @image = Gosu::Image.new("images/left_arrow.png")
    @image.draw(20, 580, ZOrder::FRONT)

    @image = Gosu::Image.new("images/right_arrow.png")
    @image.draw(380, 580, ZOrder::FRONT)

    @track_font.draw("Album Page: " + (@album_page + 1).to_s(), 135, 590, ZOrder::FRONT, 1.0, 1.0, MAIN_COLOUR)#add 1 for appearance
  end

  #track page arrows
  def draw_track_nav
    @image = Gosu::Image.new("images/left_arrow.png")
    @image.draw(460, 580, ZOrder::FRONT)

    @image = Gosu::Image.new("images/right_arrow.png")
    @image.draw(730, 580, ZOrder::FRONT)

    @track_font.draw("Track Page: " + (@track_page + 1).to_s(), 540, 590, ZOrder::FRONT, 1.0, 1.0, MAIN_COLOUR) #add 1 for appearance
  end

  #background
	def draw_background
    Gosu.draw_rect(0, 0, WIDTH, HEIGHT, BOTTOM_COLOUR, ZOrder::BACK, mode=:default)      
    Gosu.draw_rect(10, 10, ALBUM_WIDTH * 2 + 30, 630, DARK_ACCENT, ZOrder::BACK_MID, mode=:default)      
    Gosu.draw_rect(450, 10, 340, 630, DARK_ACCENT, ZOrder::BACK_MID, mode=:default)      
	end

  #titles
  def draw_title
    @track_font.draw("Ryan's Music Player - Albums", 20, 20, ZOrder::FRONT, 1.0, 1.0, MAIN_COLOUR)
    @track_font.draw("Tracks", 460, 20, ZOrder::FRONT, 1.0, 1.0, MAIN_COLOUR)
  end

  #bottom bar
  def draw_playing
    Gosu.draw_rect(0, 650, WIDTH, 60, DARK_COLOUR, ZOrder::BACK_MID, mode=:default)  

    if(@active_track == nil)
      @track_font.draw("No Track Playing", 20, 660, ZOrder::FRONT, 1.0, 1.0, MAIN_COLOUR)
      return
    end

    #play the track
    @track_font.draw("Selected: " + @active_track.name + "...", 20, 660, ZOrder::FRONT, 1.0, 1.0, MAIN_COLOUR) #using "selected" instead of "playing" because it could technically not be playing it and Im too lazy to do it any other way
  end

  #draw song controls
  def draw_controls()
    @image = Gosu::Image.new("images/pause.png")
    @image.draw(680, 660, ZOrder::FRONT)

    @image = Gosu::Image.new("images/resume.png")
    @image.draw(720, 660, ZOrder::FRONT)

    @image = Gosu::Image.new("images/stop.png")
    @image.draw(760, 660, ZOrder::FRONT)
  end

  #mouse check
	def update
    mouse_prev = @mouse
    @mouse = button_down?(Gosu::MS_LEFT)

    if(@mouse == true && mouse_prev == false)
      @mouse_down = true
    else
      @mouse_down = false
    end     
	end

  #master draw function
	def draw
    #checking input
    query_album_click()
    query_track_click()

    query_album_switch()
    query_track_switch()

    query_controls()

		#drawing
		draw_background()
		draw_title()
    draw_albums()
    draw_tracks(@active_album)

    draw_playing()

    #navigation buttons
    draw_album_nav()
    draw_track_nav()

    draw_controls()
	end

 	def needs_cursor?; true; end
end

# Show is a method that loops through update and draw
MusicPlayerMain.new.show if __FILE__ == $0