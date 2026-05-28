import '../models/connection_category.dart';
import '../models/user_profile.dart';

/// カテゴリ別チャットテンプレート集
/// AI suggestions パネルで使用する、カテゴリに最適化された会話の口火
class ChatTemplates {
  /// プライマリカテゴリに基づいた、会話の最初の3つの提案を返す
  /// 相手の興味（interests）に応じて、テンプレートをパーソナライズ
  static List<String> getOpeners(UserProfile other) {
    final templates = _baseTemplates[other.primaryCategory] ?? _baseTemplates[ConnectionCategory.friend]!;
    final interest = other.interests.isNotEmpty ? other.interests.first : null;

    return templates.map((t) {
      if (interest != null) {
        return t.replaceAll('{interest}', interest);
      }
      return t.replaceAll('{interest}', '');
    }).take(4).toList();
  }

  /// カテゴリ別の継続会話用テンプレート
  static List<String> getFollowUps(ConnectionCategory category) {
    return _followUpTemplates[category] ?? _followUpTemplates[ConnectionCategory.friend]!;
  }

  static const Map<ConnectionCategory, List<String>> _baseTemplates = {
    ConnectionCategory.romance: [
      'はじめまして！プロフィール拝見しました。{interest}がお好きとのこと、私も興味があります✨',
      '休日はどんな風に過ごされていますか？',
      'おすすめのデートスポットがあれば教えてください',
      'よかったら今度、お茶でもしませんか？',
    ],
    ConnectionCategory.friend: [
      'こんにちは！同じ{interest}が好きで嬉しいです',
      '気軽にお話できる友達を探しているので、よろしくお願いします',
      '最近ハマっていることがあれば教えてください',
      '今度{interest}を一緒に楽しめたら嬉しいです',
    ],
    ConnectionCategory.business: [
      'はじめまして。プロフィール拝見し、ぜひお話してみたいと思いご連絡しました',
      '現在のお仕事について、もう少し詳しくお聞きできますか？',
      '{interest}の分野でご一緒できることがあれば嬉しいです',
      'お時間ある時に、オンラインかカフェでお話できればと思います',
    ],
    ConnectionCategory.learning: [
      'はじめまして！{interest}について学ばれているのですね。私も興味があります',
      '今、どんなテーマを深掘りされていますか？',
      'おすすめの書籍や勉強会があれば教えてください',
      '一緒に学べる機会があれば、ぜひご一緒したいです',
    ],
    ConnectionCategory.hobby: [
      'はじめまして！{interest}仲間が見つかって嬉しいです',
      'どれくらい{interest}をされていますか？',
      'おすすめのスポットや道具など、シェアし合えたら嬉しいです',
      '今度、一緒に{interest}しませんか？',
    ],
  };

  static const Map<ConnectionCategory, List<String>> _followUpTemplates = {
    ConnectionCategory.romance: [
      '今度の週末、お時間ありますか？',
      'お好きな食べ物はなんですか？',
      '休日の楽しみ方を教えてください',
    ],
    ConnectionCategory.friend: [
      '今度、ご飯でも行きませんか？',
      '最近観た映画でおすすめはありますか？',
      'お住まいの近くでおすすめのお店ありますか？',
    ],
    ConnectionCategory.business: [
      '今後、どのような事業展開を考えていますか？',
      'ぜひ詳しくお話する機会を作りたいです',
      'ご都合の良い日程はありますか？',
    ],
    ConnectionCategory.learning: [
      '次の勉強会はいつ頃でしょうか？',
      '一緒に取り組めるテーマがあれば嬉しいです',
      '読書会など主催されていますか？',
    ],
    ConnectionCategory.hobby: [
      '今週末はどこかへ出かけますか？',
      '使っている道具・装備を教えてください',
      'おすすめのイベントがあれば共有してください',
    ],
  };
}
