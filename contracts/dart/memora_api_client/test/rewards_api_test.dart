import 'package:test/test.dart';
import 'package:memora_api_client/memora_api_client.dart';


/// tests for RewardsApi
void main() {
  final instance = MemoraApiClient().getRewardsApi();

  group(RewardsApi, () {
    // List Rewards
    //
    //Future<RewardInventoryResponse> listRewards(String xCorrelationID, String xClientVersion, String xPlatform, { String grantId, String acceptLanguage }) async
    test('test listRewards', () async {
      // TODO
    });

    // Update Reward Placement
    //
    //Future<RewardGrant> updateRewardPlacement(String rewardGrantId, String xCorrelationID, String xClientVersion, String xPlatform, String idempotencyKey, RewardPlacementRequest rewardPlacementRequest, { String acceptLanguage }) async
    test('test updateRewardPlacement', () async {
      // TODO
    });

  });
}
