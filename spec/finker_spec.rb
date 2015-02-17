require 'spec_helper'

FILE_PATH   = '/path/to/file'
HOGERC_PATH = '/home/hoge/.hogerc'

describe Finker do
  it 'has a version number' do
    expect(Finker::VERSION).not_to be nil
  end

  describe Finker::CLI do
    before do
      FileUtils.mkdir_p('working')
      FileUtils.cd('working')

      File.open(Finker::CONFIG_FILE, 'w') do |file|
        file.write(<<-EOS)
link:
  - /path/to/file
  - $ENV_VAR:
    - .hogerc
        EOS
      end
      ENV['ENV_VAR'] = '/home/hoge'

      FileUtils.mkdir_p('/path/to')
      FileUtils.mkdir_p('/home/hoge')
    end

    describe '#setup' do
      context 'on normal' do
        before do
          [FILE_PATH, HOGERC_PATH].each do |path|
            FileUtils.touch(path)
          end

          Finker::CLI.new.setup
        end

        it 'creates symbolic links' do
          [FILE_PATH, HOGERC_PATH].each do |path|
            expect(File.lstat(path).ftype).to eq 'link'
          end
        end

        it 'moves original files' do
          expect(File.lstat('/working/path/to/file').ftype).to eq 'file'
          expect(File.lstat('/working/$ENV_VAR/.hogerc').ftype).to eq 'file'
        end

        it 'creates symbolic links pointing valid files' do
          expect(File.readlink(FILE_PATH)).to eq '/working/path/to/file'
          expect(File.readlink(HOGERC_PATH)).to eq '/working/$ENV_VAR/.hogerc'
        end

        it 'skips files set up' do
          Finker::CLI.new.setup # runs two times

          expect(File.lstat('/working/path/to/file').ftype).to eq 'file'
          expect(File.lstat('/working/$ENV_VAR/.hogerc').ftype).to eq 'file'
        end
      end

      it 'raises for not existing file' do
        expect do
          Finker::CLI.new.setup
        end.to raise_error(Finker::Errors::FileNotFound)
      end
    end
  end
end
