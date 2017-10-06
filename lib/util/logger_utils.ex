defmodule LoggerUtils do
  require Logger

  defmacro __using__(_opts) do
    quote do
      require Logger
      require LoggerUtils
    end
  end

  defmacro trace(chardata_or_fn \\ "", metadata \\ []) do
    quote do
      c_or_f = unquote(chardata_or_fn)
      msg = case is_function(c_or_f) do
        true -> c_or_f.()
        _    -> c_or_f
      end
      m = __ENV__.module |> inspect()
      {f, a} = __ENV__.function
      l = __ENV__.line
      Logger.debug("#{m}.#{f}/#{a}[:#{l}]: " <> msg, unquote(metadata))
    end
  end

  defmacro debug(string, metadata \\ []) do
    quote do
      {f, a} = __ENV__.function
      l = __ENV__.line
      file = __ENV__.file
      path = "./#{Path.relative_to_cwd(file)}"
      log_string = "#{path}:#{l} in #{f}/#{a}: " <> unquote(string)
      Logger.debug(log_string, unquote(metadata))
    end
  end

  defmacro info(string, metadata \\ []) do
    quote do
      {f, a} = __ENV__.function
      l = __ENV__.line
      file = __ENV__.file
      path = "./#{Path.relative_to_cwd(file)}"
      log_string = "#{path}:#{l} in #{f}/#{a}: " <> unquote(string)
      Logger.info(log_string, unquote(metadata))
    end
  end

  defmacro warn(string, metadata \\ []) do
    quote do
      {f, a} = __ENV__.function
      l = __ENV__.line
      file = __ENV__.file
      path = "./#{Path.relative_to_cwd(file)}"
      log_string = "#{path}:#{l} in #{f}/#{a}: " <> unquote(string)
      Logger.warn(log_string, unquote(metadata))
    end
  end

  defmacro error(string, metadata \\ []) do
    quote do
      {f, a} = __ENV__.function
      l = __ENV__.line
      file = __ENV__.file
      path = "./#{Path.relative_to_cwd(file)}"
      log_string = "#{path}:#{l} in #{f}/#{a}: " <> unquote(string)
      Logger.error(log_string, unquote(metadata))
    end
  end

  defmacro log(level, string) do
    quote do
      {f, a} = __ENV__.function
      l = __ENV__.line
      file = __ENV__.file
      path = "./#{Path.relative_to_cwd(file)}"
      log_string = "#{path}:#{l} in #{f}/#{a}: " <> unquote(string)
      case unquote(level) do
        :debug -> Logger.debug(log_string)
        :info -> Logger.info(log_string)
        :warn -> Logger.warn(log_string)
        :error -> Logger.error(log_string)
      end
    end
  end

  defmacro inspect(item, level, lambda) do
    quote do
      real_item = unquote(item)
      {f, a} = __ENV__.function
      l = __ENV__.line
      file = __ENV__.file
      path = "./#{Path.relative_to_cwd(file)}"
      log_string = "#{path}:#{l} in #{f}/#{a}: " <> unquote(lambda).(unquote(item))
      case unquote(level) do
        :debug -> Logger.debug(log_string)
        :info -> Logger.info(log_string)
        :warn -> Logger.warn(log_string)
        :error -> Logger.error(log_string)
      end
      real_item
    end
  end

  defmacro io_in(bin, level \\ :debug) do
    quote do
      {f, a} = __ENV__.function
      l = __ENV__.line
      file = __ENV__.file
      path = "./#{Path.relative_to_cwd(file)}"
      log_string = "<== #{path}:#{l} in #{f}/#{a}: " <> inspect(unquote(bin))
      case unquote(level) do
        :debug -> Logger.debug(log_string)
        :info -> Logger.info(log_string)
        :warn -> Logger.warn(log_string)
        :error -> Logger.error(log_string)
      end
      unquote(bin)
    end
  end
  defmacro io_out(bin, level \\ :debug) do
    quote do
      {f, a} = __ENV__.function
      l = __ENV__.line
      file = __ENV__.file
      path = "./#{Path.relative_to_cwd(file)}"
      log_string = "==> #{path}:#{l} in #{f}/#{a}: " <> inspect(unquote(bin))
      case unquote(level) do
        :debug -> Logger.debug(log_string)
        :info -> Logger.info(log_string)
        :warn -> Logger.warn(log_string)
        :error -> Logger.error(log_string)
      end
      unquote(bin)
    end
  end

  def remove_elixir_from_module(module) do
    case Module.split(module) do
      [Elixir|rest] -> Module.concat(rest)
      other -> Module.concat(other)
    end
  end

end
