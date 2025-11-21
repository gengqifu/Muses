#include "decoder.h"

namespace sw {

class DecoderStub : public Decoder {
 public:
  bool Open(const std::string& /*source*/) override { return true; }
  bool Read(PcmBuffer& out_buffer) override {
    out_buffer.interleaved.clear();
    out_buffer.sample_rate = 48000;
    out_buffer.channels = 2;
    return false;  // EOF immediately.
  }
  void Close() override {}

  int sample_rate() const override { return 48000; }
  int channels() const override { return 2; }
};

std::unique_ptr<Decoder> CreateStubDecoder() {
  return std::make_unique<DecoderStub>();
}

}  // namespace sw
