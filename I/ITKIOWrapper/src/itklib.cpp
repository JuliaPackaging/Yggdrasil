
// #include "jlcxx/jlcxx.hpp"
#include "jlcxx/jlcxx.hpp"
#include "jlcxx/array.hpp"
#include "jlcxx/tuple.hpp"
#include "itkImageFileReader.h"
#include "itkImageFileWriter.h"
#include "itkImage.h"
#include <vector>
#include <memory>
#include <stdexcept>

using ImageType = itk::Image<float, 3>;


class ITKImageWrapper {
private:
    ImageType::Pointer m_Image;

public:
    ITKImageWrapper(const std::string& filename) {
        auto reader = itk::ImageFileReader<ImageType>::New();
        reader->SetFileName(filename);
        reader->Update();
        m_Image = reader->GetOutput();
    }

    std::vector<double> getOrigin() const {
        auto origin = m_Image->GetOrigin();
        return {origin[0], origin[1], origin[2]};
    }

    std::vector<double> getSpacing() const {
        auto spacing = m_Image->GetSpacing();
        return {spacing[0], spacing[1], spacing[2]};
    }

    std::vector<std::size_t> getSize() const {
        auto size = m_Image->GetLargestPossibleRegion().GetSize();
        return {size[0], size[1], size[2]};
    }

    std::vector<float> getPixelData() const {
        std::vector<float> data;
        itk::ImageRegionConstIterator<ImageType> it(m_Image, m_Image->GetLargestPossibleRegion());
        for (it.GoToBegin(); !it.IsAtEnd(); ++it) {
            data.push_back(it.Get());
        }
        return data;
    }

    std::vector<double> getDirection() const {
        auto direction = m_Image->GetDirection();
        std::vector<double> direction_flat;
        for (unsigned int i = 0; i < 3; ++i) {
            for (unsigned int j = 0; j < 3; ++j) {
                direction_flat.push_back(direction[i][j]);
            }
        }
        return direction_flat;
    }

    void writeImage(const std::string& filename) const {
        auto writer = itk::ImageFileWriter<ImageType>::New();
        writer->SetFileName(filename);
        writer->SetInput(m_Image);
        writer->Update();
    }
};

// ... existing code ...

JLCXX_MODULE define_julia_module(jlcxx::Module& mod)
{
    mod.add_type<ITKImageWrapper>("ITKImageWrapper")
        .constructor<std::string>()
        .method("getOrigin", &ITKImageWrapper::getOrigin)
        .method("getSpacing", &ITKImageWrapper::getSpacing)
        .method("getSize", &ITKImageWrapper::getSize)
        .method("getPixelData", &ITKImageWrapper::getPixelData)
        .method("getDirection", &ITKImageWrapper::getDirection)  // Add this line
        .method("writeImage", &ITKImageWrapper::writeImage);

    // Explicitly map methods to the allocated type
    mod.method("getOrigin", [](ITKImageWrapper& w) { return w.getOrigin(); });
    mod.method("getSpacing", [](ITKImageWrapper& w) { return w.getSpacing(); });
    mod.method("getSize", [](ITKImageWrapper& w) { return w.getSize(); });
    mod.method("getPixelData", [](ITKImageWrapper& w) { return w.getPixelData(); });
    mod.method("getDirection", [](ITKImageWrapper& w) { return w.getDirection(); });  // Add this line
    mod.method("writeImage", [](ITKImageWrapper& w, const std::string& filename) { w.writeImage(filename); });
}
