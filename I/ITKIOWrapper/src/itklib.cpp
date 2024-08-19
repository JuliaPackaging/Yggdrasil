#include "jlcxx/jlcxx.hpp"
#include "itkImageFileReader.h"
#include "itkImageFileWriter.h"

using ImageType = itk::Image<float, 3>;

ImageType::Pointer loadImage(const std::string& filename) {
    auto reader = itk::ImageFileReader<ImageType>::New();
    reader->SetFileName(filename);
    reader->Update();
    return reader->GetOutput();
}

void writeImage(ImageType::Pointer image, const std::string& filename) {
    auto writer = itk::ImageFileWriter<ImageType>::New();
    writer->SetFileName(filename);
    writer->SetInput(image);
    writer->Update();
}

JLCXX_MODULE define_julia_module(jlcxx::Module& mod) {
    mod.method("loadImage", loadImage);
    mod.method("writeImage", writeImage);
}
