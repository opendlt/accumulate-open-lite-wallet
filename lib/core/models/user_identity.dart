// Core model for user identity - no Flutter dependencies

class UserIdentity {
  final String userId;
  final String username;
  final String publicKey;
  final String publicKeyHash;
  final String email;

  const UserIdentity({
    required this.userId,
    required this.username,
    required this.publicKey,
    required this.publicKeyHash,
    required this.email,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'username': username,
      'publicKey': publicKey,
      'publicKeyHash': publicKeyHash,
      'email': email,
    };
  }

  factory UserIdentity.fromMap(Map<String, dynamic> map) {
    return UserIdentity(
      userId: map['userId']?.toString() ?? '',
      username: map['username']?.toString() ?? '',
      publicKey: map['publicKey']?.toString() ?? '',
      publicKeyHash: map['publicKeyHash']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
    );
  }
}

class KeyPair {
  final String publicKey;
  final String privateKey;
  final String publicKeyHash;

  const KeyPair({
    required this.publicKey,
    required this.privateKey,
    required this.publicKeyHash,
  });
}
