module EV3
  module Actions
    module Brick
      include EV3::Validations::Range
      include EV3::Validations::Constant
      
      attr_accessor :firmware_version

      STRING_BUFFER_SIZE = 0x20
      
      def brick
        self
      end

      private
      
      def _device_list
        CommandComponent.new(nil, ByteCodes::INPUT_DEVICE_LIST)
          .add_parameter(:byte, 0x20) 
          .add_reply(:byte, nil, 0x20)
          .add_reply(:byte)
      end
      
      def _base(code, subcode=nil)
        CommandComponent.new(self, code, subcode)
      end

      def _firmware_version
        _base(ByteCodes::FIRMWARE_VERSION, SystemSubCodes::READ)
          .add_parameter(:byte, STRING_BUFFER_SIZE) 
          .add_reply(:string, :firmware_version=, STRING_BUFFER_SIZE)
      end

      def _play_sound(volume, frequency, duration)
        validate_range!(volume, 'volume', 0..100)
        validate_range!(frequency, 'frequency', 0..50_000) # 0 - 50,000 Hz
        validate_range!(duration, 'duration', 0..(1000 * 60 * 60 * 24 * 365)) # Up to a year

        _base(ByteCodes::SOUND, SoundSubCodes::TONE)
          .add_parameter(:byte, volume)
          .add_parameter(:short, frequency)
          .add_parameter(:short, duration)
      end

      def _led_pattern(pattern)
        validate_constant!(pattern, 'pattern', EV3::LedPattern)

        _base(ByteCodes::UI_LED, LedSubCodes::WRITE)
          .add_parameter(:byte, pattern)
      end
      
      def _update_screen
        _base(ByteCodes::UI_DRAW, DrawSubCodes::UPDATE)
      end

      def _clean_screen
        _base(ByteCodes::UI_DRAW, DrawSubCodes::CLEAN)
      end

      def _top_line(trueOrFalse)
        _base(ByteCodes::UI_DRAW, DrawSubCodes::TOP_LINE)
          .add_parameter(:boolean, trueOrFalse)
      end

      def _draw_line(color, x0, y0, x1, y1)
        _base(ByteCodes::UI_DRAW, DrawSubCodes::LINE)
          .add_parameter(:byte, color)
          .add_parameter(:ushort, x0)
          .add_parameter(:ushort, y0)
          .add_parameter(:ushort, x1)
          .add_parameter(:ushort, y1)
      end

      def _draw_dot_line(color, x0, y0, x1, y1, on_pixels, off_pixels)
        _base(ByteCodes::UI_DRAW, DrawSubCodes::DOT_LINE)
          .add_parameter(:byte, color)
          .add_parameter(:ushort, x0)
          .add_parameter(:ushort, y0)
          .add_parameter(:ushort, x1)
          .add_parameter(:ushort, y1)
          .add_parameter(:ushort, on_pixels)
          .add_parameter(:ushort, off_pixels)
      end

      def _draw_pixel(color, x, y)
        _base(ByteCodes::UI_DRAW, DrawSubCodes::PIXEL)
          .add_parameter(:byte, color)
          .add_parameter(:ushort, x)
          .add_parameter(:ushort, y)
      end

      def _draw_rectangle(color, x, y, width, height)
        _base(ByteCodes::UI_DRAW, DrawSubCodes::RECT)
          .add_parameter(:byte, color)
          .add_parameter(:ushort, x)
          .add_parameter(:ushort, y)
          .add_parameter(:ushort, width)
          .add_parameter(:ushort, height)
      end

      def _draw_filled_rectangle(color, x, y, width, height)
        _base(ByteCodes::UI_DRAW, DrawSubCodes::FILL_RECT)
          .add_parameter(:byte, color)
          .add_parameter(:ushort, x)
          .add_parameter(:ushort, y)
          .add_parameter(:ushort, width)
          .add_parameter(:ushort, height)
      end

      def _draw_inverse_rectangle(color, x, y, width, height)
        _base(ByteCodes::UI_DRAW, DrawSubCodes::INVERSE_RECT)
          .add_parameter(:byte, color)
          .add_parameter(:ushort, x)
          .add_parameter(:ushort, y)
          .add_parameter(:ushort, width)
          .add_parameter(:ushort, height)
      end

      def _draw_circle(color, x, y, radius)
        _base(ByteCodes::UI_DRAW, DrawSubCodes::CIRCLE)
          .add_parameter(:byte, color)
          .add_parameter(:ushort, x)
          .add_parameter(:ushort, y)
          .add_parameter(:ushort, radius)
      end

      def _draw_filled_circle(color, x, y, radius)
        _base(ByteCodes::UI_DRAW, DrawSubCodes::FILL_CIRCLE)
          .add_parameter(:byte, color)
          .add_parameter(:ushort, x)
          .add_parameter(:ushort, y)
          .add_parameter(:ushort, radius)
      end

      def _draw_text(color, x, y, text)
        _base(ByteCodes::UI_DRAW, DrawSubCodes::TEXT)
          .add_parameter(:byte, color)
          .add_parameter(:ushort, x)
          .add_parameter(:ushort, y)
          .add_parameter(:string, text)
      end

      def _select_font(font)
        _base(ByteCodes::UI_DRAW, DrawSubCodes::SELECT_FONT)
          .add_parameter(:byte, font)
      end
      
      def _create_dir(path)
        Command.new(:system).add_component(
          _base(SystemCommand::CREATE_DIR)
            .add_parameter(:string, path)
            .add_reply(:byte)
        )
      end
      
      def _delete_file(path)
        Command.new(:system).add_component(
          _base(SystemCommand::DELETE_FILE)
            .add_parameter(:string, path)
            .add_reply(:byte)
        )
      end
      
      def _list_files(path)
        Command.new(:system).add_component(
          _base(SystemCommand::LIST_FILES)
            .add_parameter(:ushort, 1000)
            .add_parameter(:string, path)
            .add_reply(:ubyte)
            .add_reply(:uint)
            .add_reply(:ubyte)
            .add_reply(:string, nil, 1000)
        )
      end
    end
  end
end
