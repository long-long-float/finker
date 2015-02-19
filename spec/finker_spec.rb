require 'spec_helper'

FILE_PATH   = '/path/to/file'
HOGERC_PATH = '/home/hoge/.hogerc'

describe Finker do
  it 'has a version number' do
    expect(Finker::VERSION).not_to be nil
  end

  describe Finker::CLI do
    before do |example|
      next if example.metadata[:skip_before]

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

    def self.it_makes_files_conformity
      it 'creates symbolic links' do
        [FILE_PATH, HOGERC_PATH].each do |path|
          expect(File.lstat(path).ftype).to eq 'link'
        end
      end

      it 'puts original files on current directory' do
        expect(File.lstat('/working/path/to/file').ftype).to eq 'file'
        expect(File.lstat('/working/$ENV_VAR/.hogerc').ftype).to eq 'file'
      end

      it 'creates symbolic links pointing files on current directory' do
        expect(File.readlink(FILE_PATH)).to eq '/working/path/to/file'
        expect(File.readlink(HOGERC_PATH)).to eq '/working/$ENV_VAR/.hogerc'
      end
    end

    it 'raises if config file is not existing', skip_before: true do
      expect do
        Finker::CLI.new.start
      end.to raise_error(Finker::Errors::ConfigFileNotFound)
    end

    describe '#setup' do
      before do |example|
        next if example.metadata[:skip_setup_before]

        [FILE_PATH, HOGERC_PATH].each do |path|
          FileUtils.touch(path)
        end

        Finker::CLI.new.setup
      end

      it_makes_files_conformity

      it 'skips files set up' do
        Finker::CLI.new.setup # runs two times

        expect(File.lstat('/working/path/to/file').ftype).to eq 'file'
        expect(File.lstat('/working/$ENV_VAR/.hogerc').ftype).to eq 'file'
      end

      it 'raises for not existing file', skip_setup_before: true do
        expect do
          Finker::CLI.new.setup
        end.to raise_error(Finker::Errors::FileNotFound)
      end
    end

    describe '#install' do
      before do |example|
        next if example.metadata[:skip_install_before]

        %w(/working/path/to/file /working/$ENV_VAR/.hogerc).each do |path|
          FileUtils.mkdir_p(File.dirname(path))
          FileUtils.touch(path)
        end

        Finker::CLI.new.install
      end

      it_makes_files_conformity

      it 'asks whether it removes existing file' do
        cli = Finker::CLI.new
        allow(cli).to receive(:yes?).and_return(true)

        cli.install
        expect(cli).to have_received(:yes?).twice
      end

      it 'raises for not existing file', skip_install_before: true do
        expect do
          Finker::CLI.new.install
        end.to raise_error(Finker::Errors::FileNotFound)
      end
    end

    describe '#uninstall' do
      before do |example|
        next if example.metadata[:skip_uninstall_before]

        [FILE_PATH, HOGERC_PATH].each do |path|
          FileUtils.touch(path)
        end

        Finker::CLI.new.setup

        Finker::CLI.new.uninstall
      end

      it 'returns files to declared location' do
        [FILE_PATH, HOGERC_PATH].each do |path|
          expect(File.lstat(path).ftype).to eq 'file'
        end
      end

      it 'asks whether it overrides existing file(not symbolic link)', skip_uninstall_before: true do
        [*%w(/working/path/to/file /working/$ENV_VAR/.hogerc), FILE_PATH, HOGERC_PATH].each do |path|
          FileUtils.mkdir_p(File.dirname(path))
          FileUtils.touch(path)
        end

        cli = Finker::CLI.new
        allow(cli).to receive(:yes?).and_return(true)

        cli.uninstall
        expect(cli).to have_received(:yes?).twice
      end

      it 'skips if files on declared location doesn\'t exist', skip_uninstall_before: true do
        %w(/working/path/to/file /working/$ENV_VAR/.hogerc).each do |path|
          FileUtils.mkdir_p(File.dirname(path))
          FileUtils.touch(path)
        end

        Finker::CLI.new.uninstall

        [FILE_PATH, HOGERC_PATH].each do |path|
          expect(File.exist?(path)).to be false
        end
      end

      it 'raises if files on current directory diesn\'t exist', skip_uninstall_before: true do
        expect do
          Finker::CLI.new.uninstall
        end.to raise_error(Finker::Errors::FileNotFound)
      end
    end
  end
end
