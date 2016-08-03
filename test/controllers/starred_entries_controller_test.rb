require 'test_helper'

class StarredEntriesControllerTest < ActionController::TestCase

  setup do
    flush_redis
    @user = users(:new)
    @feeds = create_feeds(@user)
    @entries = @user.entries
    @entries.each do |entry|
      StarredEntry.create_from_owners(@user, entry)
    end
  end

  test "should get index" do
    @user.starred_feed_enabled = '1'
    @user.save
    assert @user.setting_on?(:starred_feed_enabled)
    login_as @user
    get :index, starred_token: @user.starred_token, format: :xml
    assert_response :success
    assert assigns(:entries).present?
  end

  test "should not get index with starred_feed disabled" do
    login_as @user
    get :index, starred_token: @user.starred_token, format: :xml
    assert_response :not_found
  end

  test "should export starred entries" do
    Sidekiq::Worker.clear_all
    login_as @user
    post :export
    assert_redirected_to settings_import_export_url
    assert_equal 1, StarredEntriesExport.jobs.size
  end

  test "should update starred entries" do
    login_as @user
    entry = @entries.first
    assert_difference "StarredEntry.count", -1 do
      patch :update, id: entry
      assert_response :success
    end
    assert_difference "StarredEntry.count", +1 do
      patch :update, id: entry
      assert_response :success
    end
  end

end