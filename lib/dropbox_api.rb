require 'dropbox_api'

# dropbox api class
class DropboxAPI
  def initialize(token)
    handle_exceptions do
      @dropbox = DropboxApi::Client.new(token)
      @dropbox.get_current_account
    end
  rescue DropboxApi::Errors::HttpError
    @dropbox = nil
  end

  def connected?
    !@dropbox.nil?
  end

  def create_folder(name)
    @path = '/' + name
    handle_exceptions do
      @dropbox.create_folder(@path)
      @dropbox.share_folder(@path)
      @url = @dropbox.create_shared_link_with_settings(@path).url + '&lst='
    end
  end

  def url
    return @url if @url

    nil
  end

  def upload_file(local_path, rename = nil)
    return unless @url

    file_name = if rename.nil?
                  File.basename(local_path)
                else
                  rename + File.extname(local_path)
                end
    file_content = IO.read(local_path)
    remote_path = @path + '/' + file_name
    handle_exceptions do
      @dropbox.upload(remote_path, file_content)
    end
  end

  def upload_text(content, file_name)
    return unless @url

    remote_path = @path + '/' + file_name
    handle_exceptions do
      @dropbox.upload(remote_path, content, mode: 'overwrite')
    end
  end

  def handle_exceptions
    yield
  rescue TooManyWriteOperationsError
    puts 'Too many write operations error, trying again.'
    sleep 1
    retry
  end
end
