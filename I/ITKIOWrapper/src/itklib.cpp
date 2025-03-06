#include <memory>
#include <type_traits>

// Check if std::make_unique_for_overwrite is available
#if !__cpp_lib_make_unique_for_overwrite

// Define the custom implementation in the global namespace
template<typename T>
typename std::enable_if<std::is_array<T>::value, std::unique_ptr<T>>::type
make_unique_for_overwrite(std::size_t size) {
    return std::unique_ptr<T>(new typename std::remove_extent<T>::type[size]);
}

template<typename T, typename... Args>
typename std::enable_if<!std::is_array<T>::value, std::unique_ptr<T>>::type
make_unique_for_overwrite(Args&&... args) {
    return std::unique_ptr<T>(new T(std::forward<Args>(args)...));
}

// Inject the custom implementation into the std namespace
namespace std {
    using ::make_unique_for_overwrite;
}

#endif // !__cpp_lib_make_unique_for_overwrite

#include "jlcxx/jlcxx.hpp"
#include "jlcxx/array.hpp"
#include "jlcxx/tuple.hpp"
#include "itkImageFileReader.h"
#include "itkImageFileWriter.h"
#include "itkImageSeriesReader.h"
#include "itkImageSeriesWriter.h"
#include "itkGDCMImageIO.h"
#include "itkGDCMSeriesFileNames.h"
#include "itkOrientImageFilter.h"
#include "itkMetaDataObject.h"
#include "itkSpatialOrientation.h"
#include "itkSpatialOrientationAdapter.h"
#include "itkImageIOBase.h"
#include <vector>
#include <stdexcept>
#include <iostream>
#include <iomanip>
#include <sstream>
#include "itkImage.h"


using ImageType = itk::Image<float, 3>;

class ITKImageWrapper {
private:
    ImageType::Pointer m_Image;

public:
    // Constructor to load a NIfTI file or DICOM series
    ITKImageWrapper(const std::string& path, bool isDicom = false) {
        if (isDicom) {
            // Handle DICOM directory
            auto namesGenerator = itk::GDCMSeriesFileNames::New();
            namesGenerator->SetUseSeriesDetails(true);
            namesGenerator->SetDirectory(path);

            const auto& seriesUIDs = namesGenerator->GetSeriesUIDs();
            if (seriesUIDs.empty()) {
                throw std::runtime_error("No DICOM series found in the directory.");
            }

            // Read the first series
            const std::string seriesIdentifier = seriesUIDs.begin()->c_str();
            const auto& fileNames = namesGenerator->GetFileNames(seriesIdentifier);

            // Read the DICOM series
            auto reader = itk::ImageSeriesReader<ImageType>::New();
            auto dicomIO = itk::GDCMImageIO::New();
            reader->SetImageIO(dicomIO);
            reader->SetFileNames(fileNames);
            reader->Update();
            m_Image = reader->GetOutput();
        } else {
            // Handle NIfTI file
            auto reader = itk::ImageFileReader<ImageType>::New();
            reader->SetFileName(path);
            reader->Update();
            m_Image = reader->GetOutput();
        }
    }

    // Get origin
    std::vector<double> getOrigin() const {
        auto origin = m_Image->GetOrigin();
        return {origin[0], origin[1], origin[2]};
    }

    // Get spacing
    std::vector<double> getSpacing() const {
        auto spacing = m_Image->GetSpacing();
        return {spacing[0], spacing[1], spacing[2]};
    }

    // Get size
    std::vector<std::size_t> getSize() const {
        auto size = m_Image->GetLargestPossibleRegion().GetSize();
        return {size[0], size[1], size[2]};
    }

    // Get pixel data
    std::vector<float> getPixelData() const {
        std::vector<float> data;
        itk::ImageRegionConstIterator<ImageType> it(m_Image, m_Image->GetLargestPossibleRegion());
        for (it.GoToBegin(); !it.IsAtEnd(); ++it) {
            data.push_back(it.Get());
        }
        return data;
    }

    // Get direction
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

void writeImage(const std::string& filename, bool isDicom = false) const {
    if (isDicom) {
        using OutputPixelType = signed short;
        using OutputImageType = itk::Image<OutputPixelType, 2>;
        using SeriesWriterType = itk::ImageSeriesWriter<ImageType, OutputImageType>;
        
        auto writer = SeriesWriterType::New();
        auto dicomIO = itk::GDCMImageIO::New();
        
        // Configure DICOM settings
        dicomIO->SetComponentType(itk::IOComponentEnum::SHORT);
        writer->SetImageIO(dicomIO);

        // Get image properties
        ImageType::RegionType region = m_Image->GetLargestPossibleRegion();
        ImageType::SizeType size = region.GetSize();
        unsigned int numberOfSlices = size[2];

        // Generate filenames
        std::vector<std::string> outputFileNames;
        for (unsigned int i = 0; i < numberOfSlices; ++i) {
            std::ostringstream ss;
            ss << filename << "/slice_" << std::setw(3) << std::setfill('0') << i << ".dcm";
            outputFileNames.push_back(ss.str());
        }

        try {
            writer->SetInput(m_Image);
            writer->SetFileNames(outputFileNames);
            writer->Update();
        } catch (const itk::ExceptionObject& e) {
            std::cerr << "Error writing DICOM series: " << e.what() << std::endl;
            throw;
        }
    } else {
        // NIfTI writing remains unchanged
        auto writer = itk::ImageFileWriter<ImageType>::New();
        writer->SetFileName(filename);
        writer->SetInput(m_Image);
        writer->Update();
    }
}
 void reorientToLPS() {
    try {
        using OrientFilterType = itk::OrientImageFilter<ImageType, ImageType>;
        auto orientFilter = OrientFilterType::New();
        orientFilter->UseImageDirectionOn();
        orientFilter->SetInput(m_Image);
        orientFilter->SetDesiredCoordinateOrientation(itk::SpatialOrientationEnums::ValidCoordinateOrientations::ITK_COORDINATE_ORIENTATION_LPS);
        orientFilter->Update();
        
        ImageType::Pointer tempOutput = orientFilter->GetOutput();
        tempOutput->DisconnectPipeline();
        m_Image = tempOutput;
    }
    catch(const itk::ExceptionObject& e) {
        std::cerr << "Error during reorientation: " << e.what() << std::endl;
        throw;
    }
}
};

JLCXX_MODULE define_julia_module(jlcxx::Module& mod)
{
    mod.add_type<ITKImageWrapper>("ITKImageWrapper")
        .constructor<std::string>()  // For NIfTI files
        .constructor<std::string, bool>()  // For DICOM series
        .method("getOrigin", &ITKImageWrapper::getOrigin)
        .method("getSpacing", &ITKImageWrapper::getSpacing)
        .method("getSize", &ITKImageWrapper::getSize)
        .method("getPixelData", &ITKImageWrapper::getPixelData)
        .method("getDirection", &ITKImageWrapper::getDirection)
        .method("writeImage", &ITKImageWrapper::writeImage)
        .method("reorientToLPS", &ITKImageWrapper::reorientToLPS);
}

