# Encoding: UTF-8

# Ruby Hack Night Asteroids by David Andrews and Jason Schweier, 2016

require_relative 'body'
require_relative 'shot'

class Player < Body
  attr_reader :destroyed

  @@ship_image = Gosu::Image.new("media/ship.bmp")
  @@thrust_image = Gosu::Image.new("media/shipthrust.bmp")
  @@thrust_sample = Gosu::Sample.new("media/thrust.wav").play(1, 1, true)

  @@facing_upward =  3*Math::PI/2.0
  @@zero_vector = CP::Vec2.new(0.0, 0.0)

  @@invulnerable_time = 2000 # ms

  def initialize(shots, dt)
    super default_shape
    @shots = shots
    @dt = dt
    new_ship
  end

  def new_ship
    self.position = dead_center
    self.velocity = still
    self.angle = facing_upward
    @destroyed = false
    @invulnerability_expires = Gosu.milliseconds + @@invulnerable_time
  end

  def destroyed!
    @destroyed = true
  end

  def invulnerable?
    @invulnerability_expires > Gosu.milliseconds
  end

  def add_to_space(space)
    space.add_body(@shape.body)
    space.add_shape(@shape)
  end

  def reset_forces
    @shape.body.reset_forces
  end

  def apply_damping
    @shape.body.update_velocity(self.zero_gravity, 0.996, @dt)
  end

  # Directly set the position of our Player
  def warp_to(position)
    self.position = position
  end

  def starting_position
    self.position = self.dead_center
  end

  # Turn a constant speed cw
  def turn_right(rate = 6.0)
    self.spin = rate
  end

  # Turn a constant speed ccw
  def turn_left(rate = 6.0)
    self.spin = -rate
  end

  def turn_none
    self.spin = 0.0
  end

  def shoot(space)
    return if @shooting || @shots.length > 3
    Shot.new(self.position, self.angle).tap do |s|
      @shots << s
      s.add_to_space(space)
    end
    @shooting = true
  end

  def shoot_none
    @shooting = false
  end

  def hyperspace
    return if @hyperspacing
    reset_forces
    self.velocity = self.still
    self.position = self.class.random_position
    @hyperspacing = true
  end

  def hyperspace_none
    @hyperspacing = false
  end

  # Apply forward force; Chipmunk will do the rest
  # Here we must convert the angle (facing) of the body into
  # forward momentum by creating a vector in the direction of the facing
  # and with a magnitude representing the force we want to apply
  def accelerate(force = 2000.0)
    @shape.body.apply_force((self.class.radians_to_vec2(@shape.body.a) * force), self.zero_offset)
    @accelerating = true
    @@thrust_sample.resume unless @@thrust_sample.playing?
  end

  def accelerate_none
    @accelerating = false
    @@thrust_sample.pause if @@thrust_sample.playing?
  end

  def draw
    # simulate blinking when invulnerable
    blink_speed = 100
    white = 0xff_ffffff
    black = 0x00_000000

    color = invulnerable? ? blink(Gosu.milliseconds, on: white, off: black) : white
    image = @accelerating ? blink(Gosu.milliseconds, on: @@thrust_image, off: @@ship_image) : @@ship_image

    image.draw_rot(self.position.x, self.position.y, ZOrder::Player, self.angle.radians_to_gosu, 0.5, 0.5, 1, 1, color)
  end

private
  def default_body
    CP::Body.new(10.0, 150.0)
  end

  def default_shape
    # In order to create a shape, we must first define it
    # Chipmunk defines 3 types of Shapes: Segments, Circles and Polys
    # We'll use a simple, 4 sided Poly for our Player (ship)
    # You need to define the vectors so that the "top" of the Shape is towards 0 radians (the right)
    shape_array = [CP::Vec2.new(-25.0, -25.0), CP::Vec2.new(-25.0, 25.0), CP::Vec2.new(25.0, 1.0), CP::Vec2.new(25.0, -1.0)]
    CP::Shape::Poly.new(default_body, shape_array).tap do |s|
      # The collision_type of a shape allows us to set up special collision behavior
      # based on these types.  The actual value for the collision_type is arbitrary
      # and, as long as it is consistent, will work for us; of course, it helps to have it make sense
      s.collision_type = :ship
      s.object = self
    end
  end

  def blink(time, on:, off:, blink_speed: 100)
    time.div(blink_speed).even? ? on : off
  end
end
