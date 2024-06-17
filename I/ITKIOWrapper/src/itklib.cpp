#include "jlcxx/jlcxx.hpp"
#include "itkImageFileReader.h"
#include "itkImageFileWriter.h"
#include "itkNiftiImageIO.h"

using ImageType = itk::Image<float, 3>;

ImageType::Pointer read_nifti_image(const std::string& filename) {
    auto reader = itk::ImageFileReader<ImageType>::New();
    reader->SetFileName(filename);
    reader->Update();
    return reader->GetOutput();
}

void write_nifti_image(ImageType::Pointer image, const std::string& filename) {
    auto writer = itk::ImageFileWriter<ImageType>::New();
    writer->SetFileName(filename);
    writer->SetInput(image);
    writer->Update();
}

JLCXX_MODULE define_julia_module(jlcxx::Module& mod) {
    mod.method("read_nifti_image", read_nifti_image);
    mod.method("write_nifti_image", write_nifti_image);
}
