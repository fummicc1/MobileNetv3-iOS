from torchvision.models import mobilenet_v3_large, MobileNet_V3_Large_Weights
import torch.nn as nn
import torch
import coremltools as ct


class Model(nn.Module):
    def __init__(self) -> None:
        super().__init__()
        self.model = mobilenet_v3_large(
            weights=MobileNet_V3_Large_Weights.IMAGENET1K_V1.DEFAULT)
        self.activation = nn.Softmax(dim=1)

    def forward(self, img):
        out = self.model(img)
        out = self.activation(out)
        return out


model = Model()
model.eval()
input = torch.rand(1, 3, 224, 224)
scale = 1.0 / (255.0 * 0.226)
red_bias = -0.485 / 0.226
green_bias = -0.456 / 0.226
blue_bias = -0.406 / 0.226

traced_model = torch.jit.trace(model, input)
model = ct.convert(
    traced_model,
    convert_to="mlprogram",
    inputs=[
        ct.ImageType(
            name="input_1",
            shape=input.shape,
            scale=scale,
            bias=[red_bias, green_bias, blue_bias],
            color_layout="RGB",
        )
    ],
    minimum_deployment_target=ct.target.iOS15,
)
model_compressed = ct.compression_utils.affine_quantize_weights(model)
model.save("mobilenetv3.mlpackage")
model_compressed.save("mobilenetv3_compressed.mlpackage")
