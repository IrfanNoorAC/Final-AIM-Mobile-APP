
class CommunityModel {
  String name;
  String image;
  String description;
  bool isMember;
  int membersCount;
  bool isAdmin;
  
  CommunityModel({
    required this.name,
    required this.image,
    required this.description,
    required this.isMember,
    required this.membersCount,
    this.isAdmin = false,
  });
}

List<CommunityModel> communityList = [
  CommunityModel(
    name: 'Block 25',
    image: 'assets/images/c1.jpeg',
    description: 'Community for residents of Block 25',
    isMember: true,
    membersCount: 3,
  ),
  CommunityModel(
    name: 'Hearing Aid',
    image: 'assets/images/c2.jpeg',
    description: 'Support group for hearing impaired',
    isMember: false,
    membersCount: 10,
  ),
  CommunityModel(
    name: 'Crafty',
    image: 'assets/images/c3.jpeg',
    description: 'Arts and crafts community',
    isMember: false,
    membersCount: 5,
    isAdmin: true,
  ),
  CommunityModel(
    name: 'Crafty x NTU',
    image: 'assets/images/c4.jpeg',
    description: 'NTU chapter of Crafty community',
    isMember: false,
    membersCount: 5,
  ),
];

List<CommunityModel> myCommunityList = [
  CommunityModel(
    name: 'Healing',
    image: 'assets/images/c5.webp',
    description: 'Mental health support group',
    isMember: true,
    membersCount: 3,
  ),
];