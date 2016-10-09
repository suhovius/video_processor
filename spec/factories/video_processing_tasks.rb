include ActionDispatch::TestProcess

FactoryGirl.define do
  factory :video_processing_task do
    association(:user)
    trim_start { 3 }
    trim_end { 10 }

    started_at { nil }
    completed_at { nil }
    failed_at { nil }

    # Avoid using real files here
    source_video_file_name { "test_video.mov" }
    # source_video_content_type { "video/quicktime" }
    # source_video_file_size { 5471296 }
    # source_video_updated_at { Time.zone.now }
    # source_video_fingerprint { "068dd109a9939f494071d8abe94b1c0c" }
    source_video_duration { rand(10) + 15 }

    factory :video_processing_task_done do
      started_at { Time.zone.now - 5.minutes }
      completed_at { Time.zone.now }

      result_video_file_name { "test_video.mov" }
      # result_video_content_type { "video/quicktime" }
      # result_video_file_size { 5471296 }
      # result_video_updated_at { Time.zone.now }
      # result_video_fingerprint { "068dd109a9939f454071d8abe94b7c0c" }
      result_video_duration { 7 }
      state { "done" }
    end

    factory :video_processing_task_failed do
      started_at { Time.zone.now - 5.minutes }
      failed_at { Time.zone.now }
      last_error { "Some error message #{rand(100)}" }
      state { "failed" }
    end

    factory :video_processing_task_with_real_file do
      source_video { fixture_file_upload("#{::Rails.root}/spec/fixtures/videos/test_video.mov", 'video/quicktime') }

      # close files to prevent "Errno::EMFILE: Too many open files" error at specs
      after(:create) do |f|
        f.source_video.try(:close) # try is used if file could be set as nil somewhere in specs
      end
    end
  end
end
