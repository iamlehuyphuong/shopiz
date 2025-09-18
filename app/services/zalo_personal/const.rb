module ZaloPersonal::Const
  VALID_TYPE = [0, 1].freeze
  ICON_MAPPING = {
    '/-strong' => '💪',
    '/-heart' => '❤️',
    ':-((' => '😭',
    ':>' => '😊',
    ':-h' => '🤗',
    ':o' => '😮',
    ':D' => '😃',
    '/-like' => '👍',
    '/-dislike' => '👎',
    '/-haha' => '😂',
    '/-wow' => '😲',
    '/-sad' => '😢',
    '/-angry' => '😠',
    '/-kiss' => '😘',
    '/-clap' => '👏',
    '/-ok' => '👌',
    '/-party' => '🥳',
    '/-star' => '⭐',
    '/-fire' => '🔥',
    '/-cry' => '😭',
    '/-love' => '😍',
    '/-thumbsup' => '👍',
    '/-thumbsdown' => '👎'
  }.freeze

  FILE_TYPE_MAPPING = {
    'chat.photo' => 'image',
    'chat.video.msg' => 'video',
    'chat.voice' => 'audio',
    'share.file' => 'file'
  }.freeze
end
