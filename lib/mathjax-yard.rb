require "mathjax-yard/version"
require 'optparse'
require 'yaml'
require 'fileutils'


module MathJaxYard
    # Your code goes here...
  class Command
    def self.run(argv=[])
      new(argv).execute
    end

    def initialize(argv=[])
      @argv = argv
      @eq_data=Hash.new
      @eq_number =0
      @revert = false
    end

    def execute
      # @argv << '--help' if @argv.size==0
      command_parser = OptionParser.new do |opt|
        opt.on('-v', '--version','show program Version.') { |v|
          opt.version = Yardmath::VERSION
          puts opt.ver
          exit
        }
        opt.on('-r', '--revert','revert back up file to orig file.') {
          directory = @argv[0]==nil ? 'lib/../*/*.md.back' : @argv[0]
          revert(directory)
          exit
        }
        opt.on('-p', '--post','post operation.') {
          post_operation
          exit
        }
      end
      command_parser.banner = "Usage: yardmath [options] [DIRECTORY]"
      command_parser.parse!(@argv)
      directory = @argv[0]==nil ? 'lib/../*/*.md' : @argv[0]
      convert(directory)
      exit
    end

    def post_operation
      file = File.open("./mathjax.yml",'r')
      src = file.read
      p data = YAML.load(src)
      data.each_pair{|file, tags|
        File.basename(file).scan(/(.+)\.md.mjx/)
        p basename = $1
        target = "./doc/file.#{basename}.html"
        file = File.open(target,'r')
        src = file.read
        file.close
        tags.each_pair{|tag,eq|
          src.gsub!(tag,eq)
        }
        file = File.open(target,'w')
        file.print(src)
        file.close
      }
    end

    def revert(directory)
      files = Dir.glob(directory)
      files.each{|file|
        p b_file = file
        file.scan(/(.+).back$/)
        p t_file = $1
        FileUtils.mv(b_file,t_file)
      }
    end

    def convert(directory)
      files = Dir.glob(directory)
      files.each{|file|
        @eq_data[file] = Hash.new
        lines = File.readlines(file)
        output = mk_tags(lines,file)
        if @eq_data[file].size ==0
          @eq_data.delete(file) 
        else
#          write_output_on_target(file,output)
          write_output_on_backup(file,output,'.mjx')
        end
      }
      save_yaml(@eq_data,"mathjax.yml")
    end

    def write_output_on_backup(file,output,extention='.mjx')
      b_file = File.open(file+extention,'w')
      b_file.print output
      b_file.close
    end

    def write_output_on_target(file,output)
      b_file = file+'.back'
      FileUtils.mv(file,b_file)
      t_file = File.open(file,'w')
      t_file.print output
      t_file.close
    end

    def save_yaml(data,file)
      print yaml_data=YAML.dump(data)
      math_file = File.open(file,'w')
      math_file.print(yaml_data)
      math_file.close
    end

    def mk_tags(lines,file_name)
      @in_eq_block = false
      output,stored_eq="",""
      lines.each{|line|
        if @in_eq_block #inside in eq block
          if line =~/^\$\$/ #closing
            stored_eq << "$"
            output << store_eq_data(stored_eq,file_name)
            stored_eq=""
            @in_eq_block = !@in_eq_block
          else #normal op. in eq block
            p stored_eq << line
          end
        else #outside eq block
          if line =~ /\$(.+)\$/ #normal op. in line eq.
            p converted =check_multiple_match($1,file_name)
            output <<  $`+converted+$'
          elsif line =~/^\$\$/ # opening in eq block
            p line
            @in_eq_block = !@in_eq_block
            stored_eq << "$"
          else  #normal op (no eq)
            output << line
          end
        end
      }
      return output
    end

    def store_eq_data(equation,file_name)
      @eq_number+=1
      tag="$MATHJAX#{@eq_number}$"
      @eq_data[file_name][tag] = "$#{equation}$"
      return tag
    end

    def check_multiple_match(line,file)
      if !line.include?('$') or
          (line=~/^\$(.+)\$$/) then
        return store_eq_data(line,file)
      end
      inline_eq = true
      equation,text="",""
      line.each_char{|char|
        if char == '$'
          if inline_eq then
            text << store_eq_data(equation,file)
            equation = ""
          else
          end
          inline_eq = !inline_eq
        else
          inline_eq ? equation << char : text << char
        end
      }
      text << store_eq_data(equation,file)
      return text
    end
  end
end

