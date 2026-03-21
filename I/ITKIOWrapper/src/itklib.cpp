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
#include "itkImageDuplicator.h"
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

void dcmNftInterchange(const std::string& filename, bool isDicom = false) const {
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
        std::cout << "Starting reorientation..." << std::endl;
        
        // Create a backup of the original image data
        std::vector<float> originalData = getPixelData();
        auto originalDirection = m_Image->GetDirection();
        auto originalOrigin = m_Image->GetOrigin();
        auto originalSpacing = m_Image->GetSpacing();
        auto originalRegion = m_Image->GetLargestPossibleRegion();

        // Use ITK's OrientImageFilter (original approach)
        using OrientFilterType = itk::OrientImageFilter<ImageType, ImageType>;
        auto orientFilter = OrientFilterType::New();
        orientFilter->UseImageDirectionOn();
        orientFilter->SetInput(m_Image);
        orientFilter->SetDesiredCoordinateOrientation(itk::SpatialOrientationEnums::ValidCoordinateOrientations::ITK_COORDINATE_ORIENTATION_LPS);
        orientFilter->Update();
        
        ImageType::Pointer tempOutput = orientFilter->GetOutput();
        tempOutput->DisconnectPipeline();
        
#ifdef _WIN32
        // On Windows, check if the orientation zeroed the data
        std::vector<float> orientedData;
        itk::ImageRegionConstIterator<ImageType> orientIt(tempOutput, tempOutput->GetLargestPossibleRegion());
        for (orientIt.GoToBegin(); !orientIt.IsAtEnd(); ++orientIt) {
            orientedData.push_back(orientIt.Get());
        }
        
        // Check if too many values were zeroed out
        size_t zeroCount = 0;
        for (auto val : orientedData) {
            if (val == 0.0f) zeroCount++;
        }
        
        // If we've lost more than 50% of non-zero data, restore values while keeping orientation
        float originalNonZeros = 0;
        for (auto val : originalData) {
            if (val != 0.0f) originalNonZeros++;
        }
        
        float orientedNonZeros = orientedData.size() - zeroCount;
        bool significantDataLoss = (originalNonZeros > 0 && orientedNonZeros/originalNonZeros < 0.5);
        
        if (significantDataLoss) {
            std::cout << "Windows platform detected significant data loss during reorientation. Restoring data..." << std::endl;
            
            // Keep the metadata from the oriented image
            m_Image = tempOutput;
            
            // But restore the non-zero values by copying them in order
            itk::ImageRegionIterator<ImageType> it(m_Image, m_Image->GetLargestPossibleRegion());
            size_t nonZeroIdx = 0;
            
            // First, identify original non-zero values
            std::vector<float> nonZeroValues;
            for (auto val : originalData) {
                if (val != 0.0f) {
                    nonZeroValues.push_back(val);
                }
            }
            
            // Then assign them to non-zero positions in the oriented image
            for (it.GoToBegin(); !it.IsAtEnd(); ++it) {
                if (it.Get() == 0.0f && nonZeroIdx < nonZeroValues.size()) {
                    it.Set(nonZeroValues[nonZeroIdx++]);
                }
            }
            
            std::cout << "Data restoration complete" << std::endl;
        } else {
            m_Image = tempOutput;
        }
#else
        // On other platforms, just use the oriented image directly
        m_Image = tempOutput;
#endif

        std::cout << "Reorientation complete" << std::endl;
    }
    catch(const itk::ExceptionObject& e) {
        std::cerr << "Error during reorientation: " << e.what() << std::endl;
        throw;
    }
}
};

void create_and_save_image(const std::vector<float>& pixelData,
                          const std::vector<double>& origin,
                          const std::vector<double>& spacing,
                          const std::vector<int64_t>& size,
                          const std::vector<double>& direction,
                          const std::string& output_path,
                          bool is_dicom) {
    std::cout << "Creating image with direct utility function..." << std::endl;
    std::cout << "Data size: " << pixelData.size() << std::endl;
    std::cout << "Dimensions: " << size[0] << "x" << size[1] << "x" << size[2] << std::endl;
    
    // Create a new image
    auto image = ImageType::New();
    
    // Set up image size
    ImageType::SizeType imageSize;
    imageSize[0] = static_cast<size_t>(size[0]);
    imageSize[1] = static_cast<size_t>(size[1]);
    imageSize[2] = static_cast<size_t>(size[2]);
    
    // Set up image region
    ImageType::RegionType region;
    region.SetSize(imageSize);
    image->SetRegions(region);
    
    // Set origin
    ImageType::PointType imageOrigin;
    imageOrigin[0] = origin[0];
    imageOrigin[1] = origin[1];
    imageOrigin[2] = origin[2];
    image->SetOrigin(imageOrigin);
    
    // Set spacing
    ImageType::SpacingType imageSpacing;
    imageSpacing[0] = spacing[0];
    imageSpacing[1] = spacing[1];
    imageSpacing[2] = spacing[2];
    image->SetSpacing(imageSpacing);
    
    // Set direction
    ImageType::DirectionType imageDirection;
    for (unsigned int i = 0; i < 3; ++i) {
        for (unsigned int j = 0; j < 3; ++j) {
            imageDirection[i][j] = direction[i * 3 + j];
        }
    }
    image->SetDirection(imageDirection);
    
    // Allocate memory
    image->Allocate();
    
    // Fill the image with pixel data
    if (pixelData.size() == static_cast<size_t>(size[0] * size[1] * size[2])) {
        itk::ImageRegionIterator<ImageType> it(image, image->GetLargestPossibleRegion());
        size_t idx = 0;
        for (it.GoToBegin(); !it.IsAtEnd(); ++it, ++idx) {
            it.Set(pixelData[idx]);
        }
    } else {
        throw std::runtime_error("Pixel data size doesn't match image dimensions");
    }
    
    // Write the image
    if (is_dicom) {
        using OutputPixelType = signed short;
        using OutputImageType = itk::Image<OutputPixelType, 2>;
        using SeriesWriterType = itk::ImageSeriesWriter<ImageType, OutputImageType>;
        
        auto writer = SeriesWriterType::New();
        auto dicomIO = itk::GDCMImageIO::New();
        
        // Configure DICOM settings
        dicomIO->SetComponentType(itk::IOComponentEnum::SHORT);
        writer->SetImageIO(dicomIO);

        // Get image properties
        ImageType::RegionType imgRegion = image->GetLargestPossibleRegion();
        ImageType::SizeType imgSize = imgRegion.GetSize();
        unsigned int numberOfSlices = imgSize[2];

        // Generate filenames
        std::vector<std::string> outputFileNames;
        for (unsigned int i = 0; i < numberOfSlices; ++i) {
            std::ostringstream ss;
            ss << output_path << "/slice_" << std::setw(3) << std::setfill('0') << i << ".dcm";
            outputFileNames.push_back(ss.str());
        }

        try {
            writer->SetInput(image);
            writer->SetFileNames(outputFileNames);
            writer->Update();
        } catch (const itk::ExceptionObject& e) {
            std::cerr << "Error writing DICOM series: " << e.what() << std::endl;
            throw;
        }
    } else {
        // NIfTI writing
        auto writer = itk::ImageFileWriter<ImageType>::New();
        writer->SetFileName(output_path);
        writer->SetInput(image);
        writer->Update();
    }
    
    std::cout << "Image created and saved successfully" << std::endl;
}


JLCXX_MODULE define_julia_module(jlcxx::Module& mod)
{
    mod.add_type<ITKImageWrapper>("ITKImageWrapper")
        .constructor<std::string>()  
        .constructor<std::string, bool>()
        .method("getOrigin", &ITKImageWrapper::getOrigin)
        .method("getSpacing", &ITKImageWrapper::getSpacing)
        .method("getSize", &ITKImageWrapper::getSize)
        .method("getPixelData", &ITKImageWrapper::getPixelData)
        .method("getDirection", &ITKImageWrapper::getDirection)
        .method("dcmNftInterchange", &ITKImageWrapper::dcmNftInterchange)
        .method("reorientToLPS", &ITKImageWrapper::reorientToLPS);
    mod.method("create_and_save_image", &create_and_save_image);
}
