require File.dirname(__FILE__) + '/../test_helper'

class NoteControllerTest < ActionController::TestCase
  fixtures :users, :notes, :note_comments

  def test_note_create_success
    # Add a new note
    assert_difference('Note.count') do
      assert_difference('NoteComment.count') do
        post :create, {:lat => -1.0, :lon => -2.0, :name => "new_tester", :text => "This is a comment"}
      end
    end
    assert_response :success
    id = @response.body.sub(/ok/,"").to_i

    note = Note.find(id)
    assert_not_nil note
    assert_equal -1.0, note.lat
    assert_equal -2.0, note.lon
    assert_equal "open", note.status
    assert_equal 1, note.comments.count
    assert_equal "opened", note.comments.last.event
    assert_equal "This is a comment", note.comments.last.body
    assert_equal "new_tester (a)", note.author_name

    # Add a new note without a username
    assert_difference('Note.count') do
      assert_difference('NoteComment.count') do
        post :create, {:lat => -2.0, :lon => -1.0, :text => "This is a comment without username"}
      end
    end
    assert_response :success
    id = @response.body.sub(/ok/,"").to_i

    note = Note.find(id)
    assert_not_nil note
    assert_equal -2.0, note.lat
    assert_equal -1.0, note.lon
    assert_equal "open", note.status
    assert_equal 1, note.comments.count
    assert_equal "opened", note.comments.last.event
    assert_equal "This is a comment without username", note.comments.last.body
    assert_equal "NoName (a)", note.author_name

    # Add a new note with a logged in user
    basic_authorization(users(:normal_user).email, "test")
    assert_difference('Note.count') do
      assert_difference('NoteComment.count') do
        post :create, {:lat => -1.0, :lon => -1.0, :name => "new_tester", :text => "This is a comment by a user"}
      end
    end
    assert_response :success
    id = @response.body.sub(/ok/,"").to_i

    note = Note.find(id)
    assert_not_nil note
    assert_equal -1.0, note.lat
    assert_equal -1.0, note.lon
    assert_equal "open", note.status
    assert_equal 1, note.comments.count
    assert_equal "opened", note.comments.last.event
    assert_equal "This is a comment by a user", note.comments.last.body
    assert_equal users(:normal_user), note.comments.last.author
  end

  def test_note_create_fail
    assert_no_difference('Note.count') do
      assert_no_difference('NoteComment.count') do
        post :create, {:lon => -1.0, :name => "new_tester", :text => "This is a comment"}
      end
    end
    assert_response :bad_request

    assert_no_difference('Note.count') do
      assert_no_difference('NoteComment.count') do
        post :create, {:lat => -1.0, :name => "new_tester", :text => "This is a comment"}
      end
    end
    assert_response :bad_request

    assert_no_difference('Note.count') do
      assert_no_difference('NoteComment.count') do
        post :create, {:lat => -1.0, :lon => -1.0, :name => "new_tester"}
      end
    end
    assert_response :bad_request

    assert_no_difference('Note.count') do
      assert_no_difference('NoteComment.count') do
        post :create, {:lat => -100.0, :lon => -1.0, :name => "new_tester", :text => "This is a comment"}
      end
    end
    assert_response :bad_request

    assert_no_difference('Note.count') do
      assert_no_difference('NoteComment.count') do
        post :create, {:lat => -1.0, :lon => -200.0, :name => "new_tester", :text => "This is a comment"}
      end
    end
    assert_response :bad_request
  end

  def test_note_comment_create_success
    # Add a new comment
    assert_difference('NoteComment.count') do
      post :update, {:id => notes(:open_note_with_comment).id, :name => "new_tester2", :text => "This is an additional comment"}
    end
    assert_response :success

    comment = notes(:open_note_with_comment).comments.last
    assert_not_nil comment
    assert_equal "commented", comment.event
    assert_equal "This is an additional comment", comment.body
    assert_equal "new_tester2 (a)", comment.author_name

    # Add a new comment without username
    assert_difference('NoteComment.count') do
      post :update, {:id => notes(:open_note_with_comment).id, :text => "This is an additional comment without username"}
    end
    assert_response :success

    comment = notes(:open_note_with_comment).comments.last
    assert_not_nil comment
    assert_equal "commented", comment.event
    assert_equal "This is an additional comment without username", comment.body
    assert_equal "NoName (a)", comment.author_name

    # Add a new comment with a logged in user
    basic_authorization(users(:normal_user).email, "test")
    assert_difference('NoteComment.count') do
      post :update, {:id => notes(:open_note_with_comment).id, :name => "new_tester2", :text => "This is an additional comment by a user"}
    end
    assert_response :success

    comment = notes(:open_note_with_comment).comments.last
    assert_not_nil comment
    assert_equal "commented", comment.event
    assert_equal "This is an additional comment by a user", comment.body
    assert_equal users(:normal_user), comment.author
  end

  def test_note_comment_create_fail
    assert_no_difference('NoteComment.count') do
      post :update, {:name => "new_tester2", :text => "This is an additional comment"}
    end
    assert_response :bad_request

    assert_no_difference('NoteComment.count') do
      post :update, {:id => notes(:open_note_with_comment).id, :name => "new_tester2"}
    end
    assert_response :bad_request

    assert_no_difference('NoteComment.count') do
      post :update, {:id => 12345, :name => "new_tester2", :text => "This is an additional comment"}
    end
    assert_response :not_found

    assert_no_difference('NoteComment.count') do
      post :update, {:id => notes(:hidden_note_with_comment).id, :name => "new_tester2", :text => "This is an additional comment"}
    end
    assert_response :gone
  end

  def test_note_close_success
    # Close note
    post :close, {:id => notes(:open_note_with_comment).id, :name => "new_tester3"}
    assert_response :success

    note = Note.find(notes(:open_note_with_comment).id)
    assert_not_nil note
    assert_equal "closed", note.status
    assert_equal "closed", note.comments.last.event
    assert_equal "new_tester3 (a)", note.comments.last.author_name

    note.status = "open"
    note.save

    # Close note without username
    post :close, {:id => notes(:open_note_with_comment).id}
    assert_response :success

    note = Note.find(notes(:open_note_with_comment).id)
    assert_not_nil note
    assert_equal "closed", note.status
    assert_equal "closed", note.comments.last.event
    assert_equal "NoName (a)", note.comments.last.author_name

    note.status = "open"
    note.save

    # Close note as a logged in user
    basic_authorization(users(:normal_user).email, "test")
    post :close, {:id => notes(:open_note_with_comment).id, :name => "new_tester3"}
    assert_response :success

    note = Note.find(notes(:open_note_with_comment).id)
    assert_not_nil note
    assert_equal "closed", note.status
    assert_equal "closed", note.comments.last.event
    assert_equal users(:normal_user), note.comments.last.author
  end

  def test_note_close_fail
    post :close
    assert_response :bad_request

    post :close, {:id => 12345}
    assert_response :not_found

    post :close, {:id => notes(:hidden_note_with_comment).id}
    assert_response :gone
  end

  def test_note_read_success
    get :read, {:id => notes(:open_note).id}
    assert_response :success      
    assert_equal "application/xml", @response.content_type

    get :read, {:id => notes(:open_note).id, :format => "xml"}
    assert_response :success
    assert_equal "application/xml", @response.content_type

    get :read, {:id => notes(:open_note).id, :format => "rss"}
    assert_response :success
    assert_equal "application/rss+xml", @response.content_type

    get :read, {:id => notes(:open_note).id, :format => "json"}
    assert_response :success
    assert_equal "application/json", @response.content_type

    get :read, {:id => notes(:open_note).id, :format => "gpx"}
    assert_response :success
    assert_equal "application/gpx+xml", @response.content_type
  end

  def test_note_read_hidden_comment
    note = notes(:note_with_hidden_comment);
    get :read, {:id => note.id, :format => 'json'}
    assert_response :success
    js = ActiveSupport::JSON.decode(@response.body)
    assert_not_nil js
    assert_equal note.id, js["note"]["id"]
    assert_equal note.comments.count, js["note"]["comments"].count
    note.comments.count.times do |c|
      assert_equal note.comments[c].body, js["note"]["comments"][c]["body"]
    end
  end

  def test_note_read_fail
    post :read
    assert_response :bad_request

    get :read, {:id => 12345}
    assert_response :not_found

    get :read, {:id => notes(:hidden_note_with_comment).id}
    assert_response :gone
  end

  def test_note_delete_success
    delete :delete, {:id => notes(:open_note_with_comment).id}
    assert_response :success

    get :read, {:id => notes(:open_note_with_comment).id, :format => 'json'}
    assert_response :gone
  end

  def test_note_delete_fail
    delete :delete
    assert_response :bad_request

    delete :delete, {:id => 12345}
    assert_response :not_found

    delete :delete, {:id => notes(:hidden_note_with_comment).id}
    assert_response :gone
  end

  def test_get_notes_success
    get :list, {:bbox => '1,1,1.2,1.2'}
    assert_response :success
    assert_equal "text/javascript", @response.content_type

    get :list, {:bbox => '1,1,1.2,1.2', :format => 'rss'}
    assert_response :success
    assert_equal "application/rss+xml", @response.content_type

    get :list, {:bbox => '1,1,1.2,1.2', :format => 'json'}
    assert_response :success
    assert_equal "application/json", @response.content_type

    get :list, {:bbox => '1,1,1.2,1.2', :format => 'xml'}
    assert_response :success
    assert_equal "application/xml", @response.content_type

    get :list, {:bbox => '1,1,1.2,1.2', :format => 'gpx'}
    assert_response :success
    assert_equal "application/gpx+xml", @response.content_type
  end

  def test_get_notes_large_area
    get :list, {:bbox => '-2.5,-2.5,2.5,2.5'}
    assert_response :success

    get :list, {:l => '-2.5', :b => '-2.5', :r => '2.5', :t => '2.5'}
    assert_response :success

    get :list, {:bbox => '-10,-10,12,12'}
    assert_response :bad_request

    get :list, {:l => '-10', :b => '-10', :r => '12', :t => '12'}
    assert_response :bad_request
  end

  def test_get_notes_closed
    get :list, {:bbox=>'1,1,1.7,1.7', :closed => '7', :format => 'json'}
    assert_response :success
    assert_equal "application/json", @response.content_type
    js = ActiveSupport::JSON.decode(@response.body)
    assert_not_nil js
    assert_equal 4, js.count

    get :list, {:bbox=>'1,1,1.7,1.7', :closed => '0', :format => 'json'}
    assert_response :success
    assert_equal "application/json", @response.content_type
    js = ActiveSupport::JSON.decode(@response.body)
    assert_not_nil js
    assert_equal 4, js.count

    get :list, {:bbox=>'1,1,1.7,1.7', :closed => '-1', :format => 'json'}
    assert_response :success
    assert_equal "application/json", @response.content_type
    js = ActiveSupport::JSON.decode(@response.body)
    assert_not_nil js
    assert_equal 6, js.count
  end

  def test_get_notes_bad_params
    get :list, {:bbox => '-2.5,-2.5,2.5'}
    assert_response :bad_request

    get :list, {:bbox => '-2.5,-2.5,2.5,2.5,2.5'}
    assert_response :bad_request

    get :list, {:b => '-2.5', :r => '2.5', :t => '2.5'}
    assert_response :bad_request

    get :list, {:l => '-2.5', :r => '2.5', :t => '2.5'}
    assert_response :bad_request

    get :list, {:l => '-2.5', :b => '-2.5', :t => '2.5'}
    assert_response :bad_request

    get :list, {:l => '-2.5', :b => '-2.5', :r => '2.5'}
    assert_response :bad_request
  end

  def test_search_success
    get :search, {:q => 'note 1'}
    assert_response :success
    assert_equal "text/javascript", @response.content_type

    get :search, {:q => 'note 1', :format => 'xml'}
    assert_response :success
    assert_equal "application/xml", @response.content_type

    get :search, {:q => 'note 1', :format => 'json'}
    assert_response :success
    assert_equal "application/json", @response.content_type

    get :search, {:q => 'note 1', :format => 'rss'}
    assert_response :success
    assert_equal "application/rss+xml", @response.content_type

    get :search, {:q => 'note 1', :format => 'gpx'}
    assert_response :success
    assert_equal "application/gpx+xml", @response.content_type
  end

  def test_search_bad_params
    get :search
    assert_response :bad_request
  end

  def test_rss_success
    get :rss
    assert_response :success
    assert_equal "application/rss+xml", @response.content_type

    get :rss, {:bbox=>'1,1,1.2,1.2'}
    assert_response :success	
    assert_equal "application/rss+xml", @response.content_type
  end

  def test_rss_fail
    get :rss, {:bbox=>'1,1,1.2'}
    assert_response :bad_request

    get :rss, {:bbox=>'1,1,1.2,1.2,1.2'}
    assert_response :bad_request
  end

  def test_user_notes_success
    get :mine, {:display_name=>'test'}
    assert_response :success

    get :mine, {:display_name=>'pulibc_test2'}
    assert_response :success

    get :mine, {:display_name=>'non-existent'}
    assert_response :not_found	
  end
end
