defmodule StarknetExplorer.Calldata do
  def from_plain_calldata([array_len | rest], nil) do
    {calls, [_calldata_length | calldata]} =
      List.foldl(
        Enum.to_list(1..felt_to_int(array_len)),
        {[], rest},
        fn _, {acc_current, acc_rest} ->
          {new, new_rest} = get_call_header_v0(acc_rest)
          {[new | acc_current], new_rest}
        end
      )

    Enum.map(
      Enum.reverse(calls),
      fn call ->
        %{call | :calldata => Enum.slice(calldata, call.data_offset, call.data_len)}
      end
    )
  end

  # we assume contract_class_version 0.1.0
  def from_plain_calldata([array_len | rest], _contract_class_version) do
    {calls, _} =
      List.foldl(
        Enum.to_list(1..felt_to_int(array_len)),
        {[], rest},
        fn _, {acc_current, acc_rest} ->
          {new, new_rest} = get_call_header_v1(acc_rest)
          {[new | acc_current], new_rest}
        end
      )

    Enum.reverse(calls)
  end

  def get_call_header_v0([to, selector, data_offset, data_len | rest]) do
    {%{
       :address => to,
       :selector => selector,
       :data_offset => felt_to_int(data_offset),
       :data_len => felt_to_int(data_len),
       :calldata => []
     }, rest}
  end

  def get_call_header_v1([to, selector, data_len | rest]) do
    data_length = felt_to_int(data_len)
    {calldata, rest} = Enum.split(rest, data_length)

    {%{
       :address => to,
       :selector => selector,
       :data_len => felt_to_int(data_len),
       :calldata => calldata
     }, rest}
  end

  def keccak(value) do
    <<_::6, result::250>> = ExKeccak.hash_256(value)
    ("0x" <> Integer.to_string(result, 16)) |> String.downcase()
  end

  def as_fn_call(nil, _calldata) do
    nil
  end

  def as_fn_call(input, calldata) do
    %{:name => input["name"], :args => as_fn_inputs(input["inputs"], calldata)}
  end

  def as_fn_inputs(inputs, calldata) do
    {result, _} =
      List.foldl(
        inputs,
        {[], calldata},
        fn input, {acc_current, acc_calldata} ->
          {fn_input, calldata_rest} = as_fn_input(input, acc_calldata)
          {[fn_input | acc_current], calldata_rest}
        end
      )

    Enum.reverse(result)
  end

  def as_fn_input(input, calldata) do
    {value, calldata_rest} = get_value_for_type(input["type"], calldata)
    {%{:name => input["name"], :type => input["type"], :value => value}, calldata_rest}
  end

  def get_value_for_type("Uint256", [value1, value2 | rest]) do
    {[value2, value1], rest}
  end

  def get_value_for_type(_, [value | rest]) do
    {value, rest}
  end

  def felt_to_int(<<"0x", hexa_value::binary>>) do
    {value, _} = Integer.parse(hexa_value, 16)
    value
  end
end