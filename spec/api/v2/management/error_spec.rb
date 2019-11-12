describe API::V2::Management::Exceptions::Base do
  it do
    expect(API::V2::Management::Exceptions::Base.new(message: 'Wrong argument.').inspect).to eq \
      '#<API::V2::Management::Exceptions::Base: Wrong argument.>'
    expect(API::V2::Management::Exceptions::Base.new(message: 'Wrong argument.', debug_message: 'Debug chat.').inspect).to eq \
      '#<API::V2::Management::Exceptions::Base: Wrong argument. (Debug chat.)>'
  end
end
