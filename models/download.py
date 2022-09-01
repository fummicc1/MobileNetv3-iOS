from torchvision.models import mobilenet_v3_small
import coremltools

model = mobilenet_v3_small(pretrained=True)
input_shape = []
