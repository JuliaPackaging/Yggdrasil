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
#include <vector>
#include <memory>
#include <stdexcept>
#include <iostream>

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

    // Write image (NIfTI or DICOM)
    void writeImage(const std::string& filename, bool isDicom = false) const {
        if (isDicom) {
            // Save as DICOM series
            auto writer = itk::ImageSeriesWriter<ImageType, ImageType>::New();
            auto dicomIO = itk::GDCMImageIO::New();
            writer->SetImageIO(dicomIO);

            // Generate output file names
            std::vector<std::string> outputFileNames;
            for (int i = 0; i < m_Image->GetLargestPossibleRegion().GetSize()[2]; ++i) {
                outputFileNames.push_back(filename + "_" + std::to_string(i) + ".dcm");
            }

            writer->SetFileNames(outputFileNames);
            writer->SetInput(m_Image);
            writer->Update();
        } else {
            // Save as NIfTI
            auto writer = itk::ImageFileWriter<ImageType>::New();
            writer->SetFileName(filename);
            writer->SetInput(m_Image);
            writer->Update();
        }
    }

    // Reorient image to LPS
    void reorientToLPS() {
        using OrientFilterType = itk::OrientImageFilter<ImageType, ImageType>;
        auto orientFilter = OrientFilterType::New();
        orientFilter->SetInput(m_Image);
        orientFilter->SetDesiredCoordinateOrientation(itk::SpatialOrientation::ITK_COORDINATE_ORIENTATION_LPS);
        orientFilter->Update();
        m_Image = orientFilter->GetOutput();
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
