class Api::V1::VideoProcessingInfosController < ::Api::BaseController

  def index
    @video_processing_infos = current_user.video_processing_infos.order_by(created_at: :desc).page(params[:page] || 1).per(params[:per_page] || 25)
  end

  def create
    @video_processing_info = current_user.video_processing_infos.create!(video_processing_info_params)
    render status: :created, action: "show"
  end

  def restart
    @video_processing_info = current_user.video_processing_infos.find(params[:id])
    @video_processing_info.schedule!
    render status: :accepted, action: "show"
  end

  private
    def video_processing_info_params
      params.require(:video_processing_info).permit(:source_file, :trim_start, :trim_end)
    end

end
