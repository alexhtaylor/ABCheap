class ParametersController < ApplicationController
  skip_before_action :authenticate_user!, only: [:new, :create, :show]
  before_action :set_params, only: [:create]

  def show
    FakeData.where('booked != true').destroy_all
    Parameter.where('id != ?', params[:id]).destroy_all
    # FakeData.destroy_all
    @booking = Booking.new
    @parameter = Parameter.find(params[:id])
    FakeData.generate_results(@parameter)

    if @parameter.earliest_start.nil?
      if @parameter.preferred_start - 14400 < DateTime.now
        earliest_start_date = DateTime.now
      else
        earliest_start_date = @parameter.preferred_start - 14400
      end
    else
      earliest_start_date = @parameter.earliest_start
    end

    if @parameter.latest_finish.nil?
      if FakeData.all.count != 0 && FakeData.last.mode != "bus"
        latest_finish_date = @parameter.preferred_start + (120 * FakeData.last.duration) + 7200
      elsif FakeData.all.count != 0 && FakeData.last.mode == "bus"
        latest_finish_date = @parameter.preferred_start + FakeData.last.duration + 7200
      else
        latest_finish_date = DateTime.now
      end
    else
      latest_finish_date = @parameter.latest_finish
    end

    valid_data = FakeData.where("cost != 0 AND booked != true AND end_time < ? AND start_time > ?", latest_finish_date, earliest_start_date)

    if valid_data.all.count.zero?
      # @fastest = @cheapest = @recommended = FakeData.create!(
      #   origin: "No Journeys Found",
      #   destination: "",
      #   cost: 69,
      #   start_time: DateTime.new(2069,4,20,4,20,0),
      #   end_time: DateTime.new(2069,4,20,16,20,0),
      #   duration: 69,
      #   mode: "train"
      # )
      redirect_to errors_no_journeys_error_path
    else
      @fastest = valid_data.min_by(&:duration)
      @cheapest = valid_data.min_by(&:cost)
      if valid_data.where(cost: @cheapest.cost).length >= 1
        @cheapest = valid_data.find(recommended(valid_data.where(cost: @cheapest.cost), @parameter.preferred_start).first)
      end
      if valid_data.where(duration: @fastest.duration).length >= 1
        @fastest = valid_data.find(recommended(valid_data.where(duration: @fastest.duration), @parameter.preferred_start).first)
      end
      @recommended = valid_data.find(recommended(valid_data.all, @parameter.preferred_start).first)
    end

    @markers = []

    origin = { lat: Geocoder.search(@parameter.origin).first.data["lat"], lng: Geocoder.search(@parameter.origin).first.data["lon"],
      image_url: helpers.asset_url("origin.png")
    }
    @markers << origin

    destination = { lat: Geocoder.search(@parameter.destination).first.data["lat"], lng: Geocoder.search(@parameter.destination).first.data["lon"],
      image_url: helpers.asset_url("destination.png")
    }
    @markers << destination

    @markers.each do |marker|
      {
        lat: marker[:lat],
        lng: marker[:lng]
      }
    end
  end

  def recommended(data, preferred_start)
    total_cost = {}
    data.each do |trip|
      deviation = ((trip.start_time.to_time - preferred_start.to_time) / 3600).abs
      total_cost[trip.id] = (trip.cost + ((trip.duration / 60) * 7) + (deviation * 2))
    end
    total_cost.min_by { |_, v| v }
  end

  def new
    @parameter = Parameter.new
    @markers = []
  end

  def create
    @parameter = Parameter.new(set_params)
    if @parameter.save
      redirect_to parameter_path(@parameter)
    else
      render :new
    end
  end

  private

  def set_params
    params.require(:parameter).permit(:origin, :destination, :preferred_start, :earliest_start, :latest_finish)
  end
end
