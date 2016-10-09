include ActionDispatch::TestProcess

FactoryGirl.define do
  factory :video_processing_task do
    association(:user)
    trim_start { 3 }
    trim_end { 10 }
    started_at { nil }
    completed_at { nil }
    failed_at { nil }
    source_video { fixture_file_upload("#{::Rails.root}/spec/fixtures/videos/test_video.mov", 'video/quicktime') }
    source_video_duration { 15 }

    factory :video_processing_task_done do
      started_at { Time.zone.now - 5.minutes }
      completed_at { Time.zone.now }
      result_video { fixture_file_upload("#{::Rails.root}/spec/fixtures/videos/test_video.mov", 'video/quicktime') }
      result_video_duration { 15 }
      state { "done" }
    end

    factory :video_processing_task_failed do
      started_at { Time.zone.now - 5.minutes }
      failed_at { Time.zone.now }
      last_error { "Some error message #{rand(100)}" }
      state { "failed" }
    end
  end
end
