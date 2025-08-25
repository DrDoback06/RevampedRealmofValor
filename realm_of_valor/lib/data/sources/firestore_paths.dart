class FirestorePaths {
  static String userDoc(String uid) => 'users/$uid';
  static String charactersCol(String uid) => 'users/$uid/characters';
  static String characterDoc(String uid, String characterId) => 'users/$uid/characters/$characterId';
  static String inventoryDoc(String uid) => 'users/$uid/inventory';
  static String cardsCol() => 'cards';
  static String cardDoc(String cardId) => 'cards/$cardId';
  static String questsCol(String uid) => 'users/$uid/quests';
  static String questDoc(String uid, String questId) => 'users/$uid/quests/$questId';
}
