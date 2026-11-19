/// Decoder for Muse 2 EEG BLE characteristics.
///
/// Muse 2 transmits 20-byte notifications on each channel characteristic:
/// - Bytes 0..1: 16-bit packet sequence number
/// - Bytes 2..19: 18 bytes containing 12 unpacked 12-bit unsigned samples
///
/// Multiplier: 0.48828125 uV / bit
class MusePacketDecoder {
  static const double scaleFactor = 0.48828125;

  /// Decodes a 20-byte raw characteristic packet into 12 voltage values in microvolts (uV).
  static List<double> decodeChannelPacket(List<int> bytes) {
    if (bytes.length < 20) {
      return const [];
    }

    final List<double> samples = List<double>.filled(12, 0.0);

    for (int i = 0; i < 6; i++) {
      final int byteOffset = 2 + (i * 3);
      final int b0 = bytes[byteOffset];
      final int b1 = bytes[byteOffset + 1];
      final int b2 = bytes[byteOffset + 2];

      // Extract two 12-bit unsigned ints from 3 bytes
      final int raw1 = (b0 << 4) | ((b1 >> 4) & 0x0F);
      final int raw2 = ((b1 & 0x0F) << 8) | b2;

      samples[i * 2] = (raw1 - 2048) * scaleFactor;
      samples[i * 2 + 1] = (raw2 - 2048) * scaleFactor;
    }

    return samples;
  }
}
