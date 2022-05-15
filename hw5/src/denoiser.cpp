#include "denoiser.h"
#include "util/mathutil.h"

Denoiser::Denoiser() : m_useTemportal(false) {}

void Denoiser::Reprojection(const FrameInfo &frameInfo) {
    int height = m_accColor.m_height;
    int width = m_accColor.m_width;
    Matrix4x4 preWorldToScreen =
        m_preFrameInfo.m_matrix[m_preFrameInfo.m_matrix.size() - 1];
    Matrix4x4 preWorldToCamera =
        m_preFrameInfo.m_matrix[m_preFrameInfo.m_matrix.size() - 2];
#pragma omp parallel for
    for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
            // TODO Tiger : Reprojection.....
            
            m_valid(x, y) = false;
            m_misc(x, y) = Float3(0.f);
        }
    }
    std::swap(m_misc, m_accColor);
}

void Denoiser::TemporalAccumulation(const Buffer2D<Float3> &curFilteredColor) {
    int height = m_accColor.m_height;
    int width = m_accColor.m_width;
    int kernelRadius = 3;
#pragma omp parallel for
    for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {

             if (m_valid(x, y)) {
                // Tiger: Temporal clamp
                Float3 sum = Float3(0.0f), sum_sqr = Float3(0.0f);
                for (int oy = -kernelRadius; oy <= kernelRadius; oy++) {
                    for (int ox = -kernelRadius; ox <= kernelRadius; ox++) {
                        Float3 TempColor = curFilteredColor(x + ox, y + oy);
                        sum += TempColor;
                        sum_sqr += Sqr(TempColor);
                    }
                }
                Float3 mean = sum / 49.0f;
                Float3 vari = SafeSqrt(sum_sqr / 49.0f - Sqr(mean));
                Float3 color = Clamp(m_accColor(x, y), mean - vari * m_colorBoxK,  mean + vari * m_colorBoxK);
                // Tiger: Exponential moving average
                m_misc(x, y) = Lerp(color, curFilteredColor(x, y), m_alpha);
            } else {
                m_misc(x, y) = curFilteredColor(x, y);
            }
        }
    }
    std::swap(m_misc, m_accColor);
}

Buffer2D<Float3> Denoiser::Filter(const FrameInfo &frameInfo) {
    int height = frameInfo.m_beauty.m_height;
    int width = frameInfo.m_beauty.m_width;
    Buffer2D<Float3> filteredImage = CreateBuffer2D<Float3>(width, height);
    int kernelRadius = 16;
#pragma omp parallel for
    for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
            
            float sum_of_weights = 0.0;
            float sum_of_weighted_values = 0.0;

            Float3 CurrentColor = frameInfo.m_beauty(x, y);
            Float3 CurrentNormal = frameInfo.m_normal(x, y);
            Float3 CurrentPosition = frameInfo.m_position(x, y);

            // Tiger: Joint bilateral filter
            for (int jy = -kernelRadius; jy <= kernelRadius; jy++) {
                for (int jx = -kernelRadius; jx <= kernelRadius; jx++) {

                    if (jx != 0 || jy != 0) // must not be self pixel
                    {
                        Float3 TempColor = frameInfo.m_beauty(x + jx, y + jy);
                        Float3 TempNormal = frameInfo.m_normal(x + jx, y + jy);
                        Float3 TempPosition = frameInfo.m_position(x + jx, y + jy);

                        float coor_dist = SafeSqrt(Sqr(jx) + Sqr(jy)) / (2.0f * Sqr(m_sigmaCoord));
                        float color_dist = SqrDistance(CurrentColor, TempColor) / (2.0f * Sqr(m_sigmaColor));
                        float normal_dist = Sqr(SafeAcos(Dot(CurrentNormal, TempNormal))) / (2.0f * Sqr(m_sigmaNormal));
                        float plane_dist = Sqr(Dot(CurrentNormal, (TempPosition - CurrentPosition) / std::max(Distance(TempPosition, CurrentPosition), 0.001f))) / (2.0f * Sqr(m_sigmaPlane));
                        float weight =  expf(-coor_dist - color_dist - normal_dist - plane_dist);
                        sum_of_weights += weight;
                        filteredImage(x, y) += frameInfo.m_beauty(x + jx, y + jy) * weight;

                    } else { // oh... it is myself
                        sum_of_weights += 1.0;
                        filteredImage(x, y) += frameInfo.m_beauty(x, y);
                    }
                }
            }

            // Set output.
            filteredImage(x, y) /= sum_of_weights;
        }
    }
    return filteredImage;
}

void Denoiser::Init(const FrameInfo &frameInfo, const Buffer2D<Float3> &filteredColor) {
    m_accColor.Copy(filteredColor);
    int height = m_accColor.m_height;
    int width = m_accColor.m_width;
    m_misc = CreateBuffer2D<Float3>(width, height);
    m_valid = CreateBuffer2D<bool>(width, height);
}

void Denoiser::Maintain(const FrameInfo &frameInfo) { m_preFrameInfo = frameInfo; }

Buffer2D<Float3> Denoiser::ProcessFrame(const FrameInfo &frameInfo) {
    // Filter current frame
    Buffer2D<Float3> filteredColor;
    filteredColor = Filter(frameInfo);

    // Reproject previous frame color to current
    if (m_useTemportal) {
        Reprojection(frameInfo);
        TemporalAccumulation(filteredColor);
    } else {
        Init(frameInfo, filteredColor);
    }

    // Maintain
    Maintain(frameInfo);
    if (!m_useTemportal) {
        m_useTemportal = true;
    }
    return m_accColor;
}
