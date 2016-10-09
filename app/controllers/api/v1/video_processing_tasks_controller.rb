class Api::V1::VideoProcessingTasksController < ::Api::BaseController

  def index
    @video_processing_tasks = current_user.video_processing_tasks.order_by(created_at: :desc).page(params[:page] || 1).per(params[:per_page] || 25)
    render_json_with(@video_processing_tasks)
  end

  def create
    @video_processing_task = current_user.video_processing_tasks.create!(video_processing_task_params)
    MetadataProcessor.new(@video_processing_task, :source_video).process!
    @video_processing_task.enqueue! # Avoid using this at record creation callback. It is better to control it manually in this case
    render_json_with(@video_processing_task, status: :created)
  end

  def restart
    @video_processing_task = current_user.video_processing_tasks.find(params[:id])
    @video_processing_task.restart!
    render_json_with(@video_processing_task, status: :accepted)
  end

  private
    def video_processing_task_params
      params.require(:video_processing_task).permit(:source_video, :trim_start, :trim_end)
    end

end
